//
//  LiteRTBridgeSwift.mm
//  Spiku
//
//  Created by Rifky Ari on 06/05/26.
//
//  Objective-C++ wrapper bridging LiteRT-LM C++ API to Swift layer.
//  Handles memory conversions (NSString ↔ std::string) and error handling.

#import "LiteRTBridgeSwift.h"
#import "LiteRTBridge.h"
#import <Foundation/Foundation.h>

@interface LiteRTBridgeSwift ()
@property (nonatomic) void *bridgePtr;  // Opaque pointer to LiteRTBridge instance
@property (nonatomic, copy) ObjCTokenCallback streamingCallback;
@end

@implementation LiteRTBridgeSwift

- (instancetype)initWithModelPath:(NSString *)modelPath {
    self = [super init];
    if (!self) return nil;
    
    auto bridge = std::make_unique<LiteRTBridge>();
    
    try {
        if (!bridge->initialize(modelPath.UTF8String)) {
            return nil;
        }
        // Store the bridge in a void pointer
        self.bridgePtr = bridge.release();
        return self;
    } catch (const std::exception& e) {
        NSLog(@"LiteRT-LM initialization error: %s", e.what());
        return nil;
    }
}

- (NSString *)inferWithPrompt:(NSString *)prompt {
    LiteRTBridge *bridge = static_cast<LiteRTBridge *>(self.bridgePtr);
    if (!bridge || !self.isReady) {
        return nil;
    }
    
    try {
        std::string result = bridge->infer(prompt.UTF8String);
        return [NSString stringWithUTF8String:result.c_str()];
    } catch (const std::exception& e) {
        NSLog(@"Blocking inference failed: %s", e.what());
        return nil;
    }
}

- (BOOL)inferStreamingWithPrompt:(NSString *)prompt completion:(ObjCTokenCallback)completion {
    LiteRTBridge *bridge = static_cast<LiteRTBridge *>(self.bridgePtr);
    if (!bridge || !self.isReady) {
        return NO;
    }
    
    if (!completion) {
        return NO;
    }
    
    // Store callback for C++ layer to invoke
    self.streamingCallback = completion;
    
    try {
        // Create C++ callback that bridges to Objective-C block
        ObjCTokenCallback blockCompletion = completion;  // Capture for lambda
        auto cppCallback = [blockCompletion](const std::string& token, bool is_complete) {
            NSString* tokenStr = [NSString stringWithUTF8String:token.c_str()];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (blockCompletion) {
                    blockCompletion(is_complete ? nil : tokenStr, is_complete);
                }
            });
        };
        
        bool success = bridge->inferStreaming(
            prompt.UTF8String,
            cppCallback
        );
        
        return success ? YES : NO;
    } catch (const std::exception& e) {
        NSLog(@"Streaming inference exception: %s", e.what());
        return NO;
    }
}

- (NSString *)inferWithAudioPath:(NSString *)audioPath prompt:(NSString *)prompt {
    LiteRTBridge *bridge = static_cast<LiteRTBridge *>(self.bridgePtr);
    if (!bridge || !self.isReady) {
        return nil;
    }

    try {
        std::string result = bridge->inferWithAudio(
            audioPath.UTF8String, prompt.UTF8String);
        if (result.empty()) return nil;
        return [NSString stringWithUTF8String:result.c_str()];
    } catch (const std::exception& e) {
        NSLog(@"Audio inference failed: %s", e.what());
        return nil;
    }
}

- (NSString *)inferWithImagePath:(NSString *)imagePath prompt:(NSString *)prompt {
    LiteRTBridge *bridge = static_cast<LiteRTBridge *>(self.bridgePtr);
    if (!bridge || !self.isReady) {
        return nil;
    }

    try {
        std::string result = bridge->inferWithImage(
            imagePath.UTF8String, prompt.UTF8String);
        if (result.empty()) return nil;
        return [NSString stringWithUTF8String:result.c_str()];
    } catch (const std::exception& e) {
        NSLog(@"Image inference failed: %s", e.what());
        return nil;
    }
}

- (BOOL)inferStreamingWithAudioPath:(NSString *)audioPath prompt:(NSString *)prompt completion:(ObjCTokenCallback)completion {
    LiteRTBridge *bridge = static_cast<LiteRTBridge *>(self.bridgePtr);
    if (!bridge || !self.isReady) {
        return NO;
    }

    if (!completion) {
        return NO;
    }

    try {
        ObjCTokenCallback blockCompletion = completion;
        auto cppCallback = [blockCompletion](const std::string& token, bool is_complete) {
            NSString* tokenStr = [NSString stringWithUTF8String:token.c_str()];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (blockCompletion) {
                    blockCompletion(is_complete ? nil : tokenStr, is_complete);
                }
            });
        };

        bool success = bridge->inferStreamingWithAudio(
            audioPath.UTF8String, prompt.UTF8String, cppCallback);

        return success ? YES : NO;
    } catch (const std::exception& e) {
        NSLog(@"Streaming audio inference exception: %s", e.what());
        return NO;
    }
}

- (BOOL)resetConversation {
    LiteRTBridge *bridge = static_cast<LiteRTBridge *>(self.bridgePtr);
    if (!bridge || !self.isReady) {
        return NO;
    }
    try {
        return bridge->resetConversation() ? YES : NO;
    } catch (const std::exception& e) {
        NSLog(@"resetConversation failed: %s", e.what());
        return NO;
    }
}

- (BOOL)isReady {
    LiteRTBridge *bridge = static_cast<LiteRTBridge *>(self.bridgePtr);
    return bridge && bridge->isReady();
}

- (void)shutdown {
    LiteRTBridge *bridge = static_cast<LiteRTBridge *>(self.bridgePtr);
    if (bridge) {
        bridge->shutdown();
        delete bridge;
        self.bridgePtr = nullptr;
    }
    self.streamingCallback = nil;
}

@end
