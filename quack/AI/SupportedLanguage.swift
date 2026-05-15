//
//  SupportedLanguage.swift
//  Spiku
//
//  Created by Rifky Ari on 06/05/26.
//

import Foundation

/// Represents supported languages in Spiku. Restricted to English and Chinese dialects.
enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case mandarin = "Mandarin Chinese"
    case cantonese = "Cantonese"
    case taiwanese = "Taiwanese"
    
    var id: String { self.rawValue }
    
    var languageCode: String {
        switch self {
        case .english:
            return "en"
        case .mandarin:
            return "zh-CN"
        case .cantonese:
            return "yue"
        case .taiwanese:
            return "zh-TW"
        }
    }
    
    var displayName: String {
        self.rawValue
    }
}
