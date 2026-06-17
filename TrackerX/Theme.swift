import SwiftUI
import UIKit

enum AppTheme {
    static let blue = Color(red: 0.22, green: 0.72, blue: 0.42)
    static let blueSoft = dynamic(light: UIColor(red: 0.91, green: 0.98, blue: 0.93, alpha: 1), dark: UIColor(red: 0.05, green: 0.16, blue: 0.10, alpha: 1))
    static let navy = dynamic(light: UIColor(red: 0.03, green: 0.20, blue: 0.11, alpha: 1), dark: UIColor(red: 0.74, green: 0.96, blue: 0.80, alpha: 1))
    static let ink = dynamic(light: UIColor(red: 0.06, green: 0.08, blue: 0.11, alpha: 1), dark: UIColor(red: 0.93, green: 0.95, blue: 1.0, alpha: 1))
    static let secondary = dynamic(light: UIColor(red: 0.45, green: 0.48, blue: 0.55, alpha: 1), dark: UIColor(red: 0.62, green: 0.66, blue: 0.76, alpha: 1))
    static let background = dynamic(light: UIColor(red: 0.985, green: 0.995, blue: 0.985, alpha: 1), dark: UIColor(red: 0.025, green: 0.045, blue: 0.035, alpha: 1))
    static let surface = dynamic(light: .white, dark: UIColor(red: 0.055, green: 0.080, blue: 0.065, alpha: 1))
    static let canvas = dynamic(light: UIColor(red: 0.945, green: 0.980, blue: 0.955, alpha: 1), dark: UIColor(red: 0.040, green: 0.070, blue: 0.055, alpha: 1))
    static let border = dynamic(light: UIColor.black.withAlphaComponent(0.055), dark: UIColor.white.withAlphaComponent(0.08))
    static let expense = Color(red: 0.93, green: 0.34, blue: 0.37)
    static let crypto = Color(red: 0.08, green: 0.58, blue: 0.50)
    static let gold = Color(red: 0.82, green: 0.67, blue: 0.32)
    static let assistantPurple = Color(red: 0.12, green: 0.48, blue: 0.30)

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
            .shadow(color: AppTheme.blue.opacity(0.15), radius: 20, x: 0, y: 10)
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
