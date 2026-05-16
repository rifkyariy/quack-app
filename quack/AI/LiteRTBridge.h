//
//  LiteRTBridge.h
//  Spiku
//
//  Created by Rifky Ari on 06/05/26.
//
//  Objective-C++ bridge to LiteRT-LM C++ API for LLM inference.
//  Uses opaque pointers to avoid exposing C++ dependencies.

#ifndef LiteRTBridge_h
#define LiteRTBridge_h

#include <string>
#include <functional>

/// Callback type for streaming inference results token-by-token.
using TokenCallback = std::function<void(const std::string &token, bool is_complete)>;

/// Forward declaration of implementation
class LiteRTBridgeImpl;

/// Objective-C++ bridge to LiteRT-LM C++ Conversation API.
/// Handles model loading and streaming inference with KV-cache management.
class LiteRTBridge
{
public:
  /// Initializes the bridge and loads the model from disk.
  /// - Parameter modelPath: Absolute file path to the .litertlm model file.
  /// - Returns: True on success, false on failure.
  bool initialize(const std::string &modelPath);

  /// Performs streaming inference on the given prompt.
  /// - Parameter prompt: Input text (user message) for the model.
  /// - Parameter callback: Called with each token and completion status.
  /// - Returns: True on success, false on failure.
  bool inferStreaming(const std::string &prompt, TokenCallback callback);

  /// Performs streaming inference with audio input (multimodal).
  /// Constructs a JSON message with audio file path and text instruction.
  /// - Parameter audioFilePath: Path to a WAV file on disk.
  /// - Parameter textPrompt: Text instruction (e.g. "Transcribe and translate").
  /// - Parameter callback: Called with each token and completion status.
  /// - Returns: True on success, false on failure.
  bool inferStreamingWithAudio(const std::string &audioFilePath,
                               const std::string &textPrompt,
                               TokenCallback callback);

  /// Performs blocking inference and returns complete output.
  /// - Parameter prompt: Input text for the model.
  /// - Returns: Complete model output string, or empty on error.
  std::string infer(const std::string &prompt);

  /// Performs blocking inference with audio input (multimodal).
  /// - Parameter audioFilePath: Path to a WAV file on disk.
  /// - Parameter textPrompt: Text instruction.
  /// - Returns: Complete model output string, or empty on error.
  std::string inferWithAudio(const std::string &audioFilePath,
                             const std::string &textPrompt);

  /// Performs blocking inference with image input (multimodal).
  /// - Parameter imageFilePath: Path to a JPEG/PNG image file on disk.
  /// - Parameter textPrompt: Text instruction.
  /// - Returns: Complete model output string, or empty on error.
  std::string inferWithImage(const std::string &imageFilePath,
                             const std::string &textPrompt);

  /// Releases resources and cleans up the model.
  void shutdown();

  /// Returns true if the model is loaded and ready.
  bool isReady() const;

  LiteRTBridge();
  ~LiteRTBridge();

  // Non-copyable, non-movable
  LiteRTBridge(const LiteRTBridge &) = delete;
  LiteRTBridge &operator=(const LiteRTBridge &) = delete;
  LiteRTBridge(LiteRTBridge &&) = delete;
  LiteRTBridge &operator=(LiteRTBridge &&) = delete;

private:
  LiteRTBridgeImpl *impl_;
};

#endif /* LiteRTBridge_h */
