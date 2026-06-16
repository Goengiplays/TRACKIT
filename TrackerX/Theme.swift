import SwiftUI
import UIKit

enum AppTheme {
    static let blue = Color(red: 0.24, green: 0.49, blue: 1.0)
    static let blueSoft = dynamic(light: UIColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1), dark: UIColor(red: 0.09, green: 0.14, blue: 0.24, alpha: 1))
    static let navy = dynamic(light: UIColor(red: 0.05, green: 0.12, blue: 0.24, alpha: 1), dark: UIColor(red: 0.72, green: 0.82, blue: 1.0, alpha: 1))
    static let ink = dynamic(light: UIColor(red: 0.06, green: 0.08, blue: 0.11, alpha: 1), dark: UIColor(red: 0.93, green: 0.95, blue: 1.0, alpha: 1))
    static let secondary = dynamic(light: UIColor(red: 0.45, green: 0.48, blue: 0.55, alpha: 1), dark: UIColor(red: 0.62, green: 0.66, blue: 0.76, alpha: 1))
    static let background = dynamic(light: UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1), dark: UIColor(red: 0.035, green: 0.045, blue: 0.065, alpha: 1))
    static let surface = dynamic(light: .white, dark: UIColor(red: 0.075, green: 0.085, blue: 0.115, alpha: 1))
    static let canvas = dynamic(light: UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1), dark: UIColor(red: 0.055, green: 0.065, blue: 0.095, alpha: 1))
    static let border = dynamic(light: UIColor.black.withAlphaComponent(0.055), dark: UIColor.white.withAlphaComponent(0.08))
    static let expense = Color(red: 0.93, green: 0.34, blue: 0.37)
    static let crypto = Color(red: 0.46, green: 0.36, blue: 0.95)
    static let gold = Color(red: 0.82, green: 0.67, blue: 0.32)
    static let assistantPurple = Color(red: 0.43, green: 0.18, blue: 1.0)

    static let lime = blue
    static let limeSoft = blueSoft
    static let forest = navy

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

extension View {
    func trackerCard(radius: CGFloat = 24) -> some View {
        self
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .shadow(color: AppTheme.blue.opacity(0.12), radius: 18, x: 0, y: 8)
    }
}

extension Double {
    var currency: String {
        formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    var compactCurrency: String {
        let absolute = abs(self)
        let sign = self < 0 ? "−" : ""
        if absolute >= 1_000_000 {
            return "\(sign)$\(String(format: "%.1f", absolute / 1_000_000))M"
        }
        if absolute >= 1_000 {
            return "\(sign)$\(String(format: "%.1f", absolute / 1_000))K"
        }
        return currency
    }
}
