//
//  LiteRTBridgeSwift.h
//  Spiku
//
//  Created by Rifky Ari on 06/05/26.
//
//  Objective-C wrapper for LiteRT-LM C++ Conversation API.
//  Provides NSString/NSError interop for Swift layer.

#ifndef LiteRTBridgeSwift_h
#define LiteRTBridgeSwift_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Typedef for token callback (called as tokens are streamed).
typedef void (^ObjCTokenCallback)(NSString *_Nullable token, BOOL isComplete);

/// Objective-C wrapper for LiteRTBridge C++ class.
/// Wraps LiteRT-LM Conversation API for streaming and blocking inference.
@interface LiteRTBridgeSwift : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Initializes the wrapper and loads the model using LiteRT-LM Engine.
/// - Parameter modelPath: Absolute file path to the .litertlm model.
/// - Returns: Initialized instance, or nil on failure.
- (instancetype)initWithModelPath:(NSString *)modelPath;

/// Performs blocking inference and returns complete output.
/// - Parameter prompt: Input text (user message).
/// - Returns: Complete model output string, or nil on failure.
- (NSString *_Nullable)inferWithPrompt:(NSString *)prompt;

/// Performs streaming inference with token-by-token callback.
/// - Parameter prompt: Input text (user message).
/// - Parameter completion: Called for each token and on completion.
/// - Returns: YES on success, NO on failure.
- (BOOL)inferStreamingWithPrompt:(NSString *)prompt completion:(ObjCTokenCallback)completion;

/// Performs blocking inference with audio file input (multimodal).
/// - Parameter audioPath: Absolute path to a WAV audio file on disk.
/// - Parameter prompt: Text instruction (e.g. transcription/translation instructions).
/// - Returns: Complete model output string, or nil on failure.
- (NSString *_Nullable)inferWithAudioPath:(NSString *)audioPath prompt:(NSString *)prompt;

/// Performs streaming inference with audio file input (multimodal).
/// - Parameter audioPath: Absolute path to a WAV audio file on disk.
/// - Parameter prompt: Text instruction.
/// - Parameter completion: Called for each token and on completion.
/// - Returns: YES on success, NO on failure.
- (BOOL)inferStreamingWithAudioPath:(NSString *)audioPath prompt:(NSString *)prompt completion:(ObjCTokenCallback)completion;

/// Returns true if the model is loaded and ready.
@property(nonatomic, readonly) BOOL isReady;

/// Explicitly releases resources and shuts down the engine.
- (void)shutdown;

@end

NS_ASSUME_NONNULL_END

#endif /* LiteRTBridgeSwift_h */
