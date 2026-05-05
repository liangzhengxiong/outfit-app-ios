import UIKit

enum WTWColor {
    static let primary = UIColor(hex: "#1A365D")
    static let secondary = UIColor(hex: "#FFFFFF")
    static let textPrimary = UIColor(hex: "#2D2D2D")
    static let backgroundSub = UIColor(hex: "#F5F5F5")
    static let disabled = UIColor(hex: "#C9CDD4")
    static let accent = UIColor(hex: "#F59F45")

    static let separator = UIColor(hex: "#C9CDD4")
    static let cardShadow = UIColor.black.withAlphaComponent(0.1)
}

enum WTWFont {
    static func title() -> UIFont {
        return .systemFont(ofSize: 20, weight: .bold)
    }

    static func cardTitle() -> UIFont {
        return .systemFont(ofSize: 18, weight: .semibold)
    }

    static func body() -> UIFont {
        return .systemFont(ofSize: 16, weight: .regular)
    }

    static func caption() -> UIFont {
        return .systemFont(ofSize: 14, weight: .light)
    }

    static func button() -> UIFont {
        return .systemFont(ofSize: 16, weight: .medium)
    }
}

enum WTWLayout {
    static let cornerRadius: CGFloat = 4
    static let buttonHeight: CGFloat = 48
    static let smallButtonHeight: CGFloat = 36
    static let inputHeight: CGFloat = 44
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 20
    static let cardSpacing: CGFloat = 12
    static let listSpacing: CGFloat = 8
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}