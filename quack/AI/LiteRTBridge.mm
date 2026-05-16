//
//  LiteRTBridge.mm
//  Spiku
//
//  Created by Rifky Ari on 06/05/26.
//
//  Implementation of LiteRT-LM C++ bridge for iOS.
//  Uses real LiteRT-LM Engine + Conversation API.

#import "LiteRTBridge.h"
#import <Foundation/Foundation.h>

#include <iostream>
#include <memory>
#include <string>

#include "runtime/engine/engine.h"
#include "runtime/engine/engine_settings.h"
#include "runtime/engine/engine_factory.h"
#include "runtime/conversation/conversation.h"
#include "runtime/conversation/io_types.h"
#include "nlohmann/json.hpp"

using namespace litert::lm;
using json = nlohmann::ordered_json;

class LiteRTBridgeImpl {
public:
  std::unique_ptr<Engine> engine;
  std::unique_ptr<Conversation> conversation;
  bool is_ready = false;
};

// MARK: - LiteRTBridge

LiteRTBridge::LiteRTBridge() : impl_(new LiteRTBridgeImpl()) {}

LiteRTBridge::~LiteRTBridge() {
  shutdown();
  if (impl_) {
    delete impl_;
    impl_ = nullptr;
  }
}

bool LiteRTBridge::initialize(const std::string &modelPath) {
  if (!impl_) return false;

  try {
    std::cout << "Initializing LiteRT-LM model: " << modelPath << std::endl;

    // 1. Create ModelAssets from file path
    auto model_assets_or = ModelAssets::Create(
        std::string_view(modelPath.data(), modelPath.size()));
    if (!model_assets_or.ok()) {
      std::cerr << "ModelAssets::Create failed: "
                << model_assets_or.status().message() << std::endl;
      return false;
    }
    std::cout << "ModelAssets created successfully" << std::endl;

    // 2. Create EngineSettings with GPU backend (iOS Metal)
    //    Audio encoder/adapter models are CPU-constrained, so pass CPU as audio_backend.
    // CPU backend for main executor: Metal GPU delegate does not support
    // external embeddings from the audio pipeline (Node 1107 invoke failure).
    // Audio encoder and adapter are CPU-constrained by the model itself.
    auto engine_settings_or = EngineSettings::CreateDefault(
        std::move(*model_assets_or), Backend::CPU,
        /*vision_backend=*/Backend::CPU,
        /*audio_backend=*/Backend::CPU);
    if (!engine_settings_or.ok()) {
      std::cerr << "EngineSettings::CreateDefault failed: "
                << engine_settings_or.status().message() << std::endl;
      return false;
    }
    std::cout << "EngineSettings created successfully" << std::endl;

    // 2b. Set cache directory to a writable iOS path
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(
        NSCachesDirectory, NSUserDomainMask, YES);
    if (cachePaths.count > 0) {
      NSString *cacheDir = [cachePaths[0] stringByAppendingPathComponent:@"litert_cache"];

      // Clear stale Metal shader cache from previous (text-only) sessions.
      // The mldrift cache is configuration-dependent and must be rebuilt
      // when the engine config changes (e.g. audio modality enabled).
      NSString *markerFile = [cacheDir stringByAppendingPathComponent:@".vision_cache_v1"];
      if (![[NSFileManager defaultManager] fileExistsAtPath:markerFile]) {
        std::cout << "Clearing stale Metal shader cache for vision-enabled config" << std::endl;
        [[NSFileManager defaultManager] removeItemAtPath:cacheDir error:nil];
      }

      [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil];

      // Write marker so we only clear cache once per config change
      [@"1" writeToFile:markerFile atomically:YES encoding:NSUTF8StringEncoding error:nil];

      std::string cacheDirStr = std::string([cacheDir UTF8String]);
      engine_settings_or->GetMutableMainExecutorSettings().SetCacheDir(cacheDirStr);
      // Also set cache dir for audio executor (CPU-based audio encoder/adapter)
      if (engine_settings_or->GetAudioExecutorSettings().has_value()) {
        engine_settings_or->GetMutableAudioExecutorSettings()->SetCacheDir(cacheDirStr);
      }
      // Also set cache dir for the vision executor (CPU-based vision encoder).
      if (engine_settings_or->GetVisionExecutorSettings().has_value()) {
        engine_settings_or->GetMutableVisionExecutorSettings()->SetCacheDir(cacheDirStr);
      }
      std::cout << "Cache directory set to: " << cacheDirStr << std::endl;
    }

    // 3. Create Engine via EngineFactory
    auto engine_or = EngineFactory::CreateDefault(
        std::move(*engine_settings_or));
    if (!engine_or.ok()) {
      std::cerr << "EngineFactory::CreateDefault failed: "
                << engine_or.status().message() << std::endl;
      return false;
    }
    impl_->engine = std::move(*engine_or);
    std::cout << "Engine created successfully" << std::endl;

    // 4. Create ConversationConfig with audio + vision modalities enabled
    auto session_config = SessionConfig::CreateDefault();
    session_config.SetAudioModalityEnabled(true);
    session_config.SetVisionModalityEnabled(true);

    auto config_or = ConversationConfig::Builder()
        .SetSessionConfig(session_config)
        .Build(*impl_->engine);
    if (!config_or.ok()) {
      std::cerr << "ConversationConfig::Build failed: "
                << config_or.status().message() << std::endl;
      return false;
    }
    std::cout << "ConversationConfig created successfully (audio + vision enabled)"
              << std::endl;

    // 5. Create Conversation
    auto conversation_or = Conversation::Create(
        *impl_->engine, *config_or);
    if (!conversation_or.ok()) {
      std::cerr << "Conversation::Create failed: "
                << conversation_or.status().message() << std::endl;
      return false;
    }
    impl_->conversation = std::move(*conversation_or);
    std::cout << "Conversation created successfully" << std::endl;

    impl_->is_ready = true;
    std::cout << "LiteRT-LM initialized successfully" << std::endl;
    return true;
  } catch (const std::exception &e) {
    std::cerr << "Initialization exception: " << e.what() << std::endl;
    impl_->is_ready = false;
    return false;
  }
}

std::string LiteRTBridge::infer(const std::string &prompt) {
  if (!impl_ || !impl_->is_ready || !impl_->conversation) {
    return "";
  }

  try {
    // Build a JSON message in the format expected by LiteRT-LM Conversation API
    json message = {
      {"role", "user"},
      {"content", prompt}
    };

    std::cout << "Sending message to LiteRT-LM..." << std::endl;

    auto result_or = impl_->conversation->SendMessage(message);
    if (!result_or.ok()) {
      std::cerr << "SendMessage failed: "
                << result_or.status().message() << std::endl;
      return "";
    }

    // Extract the response content from the JSON message.
    // Gemma 4 returns `content` as an array of {type,text} parts even for
    // text-only prompts — accept both shapes.
    const json& response = *result_or;
    std::string output;
    if (response.contains("content")) {
      if (response["content"].is_string()) {
        output = response["content"].get<std::string>();
      } else if (response["content"].is_array()) {
        for (const auto& item : response["content"]) {
          if (item.contains("text")) {
            output += item["text"].get<std::string>();
          }
        }
      } else {
        output = response["content"].dump();
      }
    } else {
      output = response.dump();
    }

    std::cout << "LiteRT-LM response received (" << output.size() << " chars)" << std::endl;
    return output;
  } catch (const std::exception &e) {
    std::cerr << "Inference exception: " << e.what() << std::endl;
    return "";
  }
}

std::string LiteRTBridge::inferWithAudio(const std::string &audioFilePath,
                                         const std::string &textPrompt) {
  if (!impl_ || !impl_->is_ready || !impl_->conversation) {
    return "";
  }

  try {
    // Build multimodal message with audio file path and text instruction
    json content = json::array();
    content.push_back({{"type", "audio"}, {"path", audioFilePath}});
    content.push_back({{"type", "text"}, {"text", textPrompt}});

    json message = {
      {"role", "user"},
      {"content", content}
    };

    std::cout << "Sending audio message to LiteRT-LM (audio: "
              << audioFilePath << ")" << std::endl;

    auto result_or = impl_->conversation->SendMessage(message);
    if (!result_or.ok()) {
      std::cerr << "SendMessage (audio) failed: "
                << result_or.status().message() << std::endl;
      return "";
    }

    const json& response = *result_or;
    std::string output;
    if (response.contains("content")) {
      if (response["content"].is_string()) {
        output = response["content"].get<std::string>();
      } else if (response["content"].is_array()) {
        for (const auto& item : response["content"]) {
          if (item.contains("text")) {
            output += item["text"].get<std::string>();
          }
        }
      } else {
        output = response["content"].dump();
      }
    } else {
      output = response.dump();
    }

    std::cout << "LiteRT-LM audio response received (" << output.size()
              << " chars)" << std::endl;
    return output;
  } catch (const std::exception &e) {
    std::cerr << "Audio inference exception: " << e.what() << std::endl;
    return "";
  }
}

std::string LiteRTBridge::inferWithImage(const std::string &imageFilePath,
                                         const std::string &textPrompt) {
  if (!impl_ || !impl_->is_ready || !impl_->conversation) {
    return "";
  }

  try {
    // Build multimodal message with image file path and text instruction.
    json content = json::array();
    content.push_back({{"type", "image"}, {"path", imageFilePath}});
    content.push_back({{"type", "text"}, {"text", textPrompt}});

    json message = {
      {"role", "user"},
      {"content", content}
    };

    std::cout << "Sending image message to LiteRT-LM (image: "
              << imageFilePath << ")" << std::endl;

    auto result_or = impl_->conversation->SendMessage(message);
    if (!result_or.ok()) {
      std::cerr << "SendMessage (image) failed: "
                << result_or.status().message() << std::endl;
      return "";
    }

    const json& response = *result_or;
    std::string output;
    if (response.contains("content")) {
      if (response["content"].is_string()) {
        output = response["content"].get<std::string>();
      } else if (response["content"].is_array()) {
        for (const auto& item : response["content"]) {
          if (item.contains("text")) {
            output += item["text"].get<std::string>();
          }
        }
      } else {
        output = response["content"].dump();
      }
    } else {
      output = response.dump();
    }

    std::cout << "LiteRT-LM image response received (" << output.size()
              << " chars)" << std::endl;
    return output;
  } catch (const std::exception &e) {
    std::cerr << "Image inference exception: " << e.what() << std::endl;
    return "";
  }
}

bool LiteRTBridge::inferStreamingWithAudio(const std::string &audioFilePath,
                                            const std::string &textPrompt,
                                            TokenCallback callback) {
  if (!impl_ || !impl_->is_ready || !impl_->conversation) {
    return false;
  }

  try {
    // Build multimodal message with audio file path and text instruction
    json content = json::array();
    content.push_back({{"type", "audio"}, {"path", audioFilePath}});
    content.push_back({{"type", "text"}, {"text", textPrompt}});

    json message = {
      {"role", "user"},
      {"content", content}
    };

    std::cout << "Sending streaming audio message to LiteRT-LM (audio: "
              << audioFilePath << ")" << std::endl;

    auto status = impl_->conversation->SendMessageAsync(
        message,
        [callback](absl::StatusOr<json> chunk_or) {
          if (!chunk_or.ok()) {
            callback("", true);
            return;
          }

          const json& chunk = *chunk_or;

          if (chunk.empty()) {
            callback("", true);
            return;
          }

          std::string token;
          if (chunk.contains("content")) {
            if (chunk["content"].is_string()) {
              token = chunk["content"].get<std::string>();
            } else if (chunk["content"].is_array()) {
              for (const auto& item : chunk["content"]) {
                if (item.contains("text")) {
                  token += item["text"].get<std::string>();
                }
              }
            } else {
              token = chunk["content"].dump();
            }
          } else {
            token = chunk.dump();
          }

          if (!token.empty()) {
            callback(token, false);
          }
        });

    if (!status.ok()) {
      std::cerr << "SendMessageAsync (audio) failed: "
                << status.message() << std::endl;
      return false;
    }

    return true;
  } catch (const std::exception &e) {
    std::cerr << "Streaming audio inference exception: " << e.what()
              << std::endl;
    return false;
  }
}

bool LiteRTBridge::inferStreaming(const std::string &prompt,
                                   TokenCallback callback) {
  if (!impl_ || !impl_->is_ready || !impl_->conversation) {
    return false;
  }

  try {
    json message = {
      {"role", "user"},
      {"content", prompt}
    };

    std::cout << "Sending streaming message to LiteRT-LM..." << std::endl;

    // Use SendMessageAsync for token-by-token streaming
    auto status = impl_->conversation->SendMessageAsync(
        message,
        [callback](absl::StatusOr<json> chunk_or) {
          if (!chunk_or.ok()) {
            // Error or cancellation
            callback("", true);
            return;
          }

          const json& chunk = *chunk_or;

          // Empty message signals completion
          if (chunk.empty()) {
            callback("", true);
            return;
          }

          // Extract content from the chunk
          std::string token;
          if (chunk.contains("content")) {
            token = chunk["content"].get<std::string>();
          } else {
            token = chunk.dump();
          }

          if (!token.empty()) {
            callback(token, false);
          }
        });

    if (!status.ok()) {
      std::cerr << "SendMessageAsync failed: "
                << status.message() << std::endl;
      return false;
    }

    return true;
  } catch (const std::exception &e) {
    std::cerr << "Streaming inference exception: " << e.what() << std::endl;
    return false;
  }
}

void LiteRTBridge::shutdown() {
  if (impl_) {
    impl_->conversation.reset();
    impl_->engine.reset();
    impl_->is_ready = false;
  }
}

bool LiteRTBridge::isReady() const {
  return impl_ && impl_->is_ready;
}
