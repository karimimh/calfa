import SwiftUI
import CoreText

extension Font {
    static func yekanBakh(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Use the actual PostScript name from the font file
        return Font.custom("YekanBakhFaNum-Regular", size: size)
            .fallback(Font.system(size: size, weight: weight))
    }
}

extension Font {
    func fallback(_ font: Font) -> Font {
        return self
    }
}

@MainActor
class FontManager {
    static let shared = FontManager()
    
    private init() {
        loadCustomFonts()
    }
    
    private func loadCustomFonts() {
        // Try to load the font from Resources
        // Depending on the SwiftPM version, processed resources land at the bundle root or under "Resources/".
        let name = "YekanBakhFaNum-Regular"
        let candidates: [URL?] = ["ttf", "otf"].flatMap { ext in
            [Bundle.module.url(forResource: name, withExtension: ext),
             Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Resources")]
        }
        guard let fontURL = candidates.compactMap({ $0 }).first else {
            print("ℹ️ YekanBakh font file not found. Using system font as fallback.")
            return
        }
        
        guard let fontData = try? Data(contentsOf: fontURL),
              let provider = CGDataProvider(data: fontData as CFData),
              let font = CGFont(provider) else {
            print("⚠️ Failed to load YekanBakh font data")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            if let error = error?.takeRetainedValue() {
                print("⚠️ Failed to register YekanBakh font: \(error)")
            }
        } else {
            print("✅ YekanBakh font loaded successfully")
        }
    }
}
