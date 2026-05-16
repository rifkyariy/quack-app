import AVFoundation
import SwiftUI
import UIKit

/// Single-shot still-image camera for the Camera Mission. Owns an
/// AVCaptureSession, exposes a SwiftUI live preview, and captures one
/// downscaled JPEG on demand. Analogous to MicRecorder for audio.
@MainActor
final class CameraCapture: NSObject {
    enum CaptureError: LocalizedError {
        case permissionDenied
        case unavailable
        case captureFailed(String)

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Camera access was denied. Enable it in Settings to play Scan it."
            case .unavailable:
                return "No camera is available on this device."
            case .captureFailed(let detail):
                return "Could not take the photo: \(detail)"
            }
        }
    }

    /// The session backing the live preview. Read-only to callers.
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var configured = false
    private var captureContinuation: CheckedContinuation<Data, Error>?
    private let sessionQueue = DispatchQueue(label: "dev.quack.camera.session")

    /// True when this device actually has a usable camera (false in Simulator).
    var isAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    /// Requests camera permission, returning the final granted state.
    func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    /// Wires up the back camera and photo output. Safe to call repeatedly.
    func configure() throws {
        guard !configured else { return }
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)
        else {
            throw CaptureError.unavailable
        }
        session.beginConfiguration()
        session.sessionPreset = .photo
        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            session.commitConfiguration()
            throw CaptureError.captureFailed(error.localizedDescription)
        }
        guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            throw CaptureError.unavailable
        }
        session.addInput(input)
        session.addOutput(photoOutput)
        session.commitConfiguration()
        configured = true
    }

    /// Starts the capture session on a serial background queue.
    func start() {
        guard configured else { return }
        let session = self.session
        sessionQueue.async { if !session.isRunning { session.startRunning() } }
    }

    /// Stops the capture session. Resumes any in-flight capture with an error
    /// first — stopRunning may otherwise drop the delegate callback, leaking
    /// the continuation and hanging its awaiting task.
    func stop() {
        if let continuation = captureContinuation {
            captureContinuation = nil
            continuation.resume(throwing: CaptureError.captureFailed("Capture cancelled"))
        }
        let session = self.session
        sessionQueue.async { if session.isRunning { session.stopRunning() } }
    }

    /// Captures one still photo and returns it as a downscaled JPEG.
    func capturePhoto() async throws -> Data {
        guard configured else { throw CaptureError.unavailable }
        guard captureContinuation == nil else {
            throw CaptureError.captureFailed("A capture is already in progress")
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.captureContinuation = continuation
            self.photoOutput.capturePhoto(
                with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    /// Downscales a UIImage so its longest side is at most `maxDimension`,
    /// then JPEG-encodes it. Full-resolution photos waste vision-encoder time.
    fileprivate static func downscaledJPEG(_ image: UIImage, maxDimension: CGFloat) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

extension CameraCapture: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            guard let continuation = self.captureContinuation else { return }
            self.captureContinuation = nil
            if let error {
                continuation.resume(
                    throwing: CaptureError.captureFailed(error.localizedDescription))
                return
            }
            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data),
                  let jpeg = Self.downscaledJPEG(image, maxDimension: 768)
            else {
                continuation.resume(
                    throwing: CaptureError.captureFailed("Could not encode photo"))
                return
            }
            continuation.resume(returning: jpeg)
        }
    }
}

/// SwiftUI live-camera preview backed by an AVCaptureVideoPreviewLayer.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
