//
//  GlassCard.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//


import SwiftUI

enum SpeakEasyPalette {
    static let backgroundTop = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.10, blue: 0.12, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.96, blue: 0.93, alpha: 1.0)
    })
    static let backgroundBottom = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.15, blue: 0.18, alpha: 1.0)
            : UIColor(red: 0.92, green: 0.95, blue: 0.97, alpha: 1.0)
    })
    static let cardFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.white.withAlphaComponent(0.84)
    })
    static let cardBorder = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.white.withAlphaComponent(0.78)
    })
    static let ink = Color(uiColor: .label)
    static let mutedInk = Color(uiColor: .secondaryLabel)
    static let secondarySurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let tertiarySurface = Color(uiColor: .tertiarySystemGroupedBackground)
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                SpeakEasyPalette.cardFill,
                                colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.68)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(SpeakEasyPalette.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.08), radius: 24, x: 0, y: 16)
            .shadow(color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.45), radius: 8, x: 0, y: -2)
    }
}

// MARK: - Glass Text Field
struct GlassTextField: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(SpeakEasyPalette.mutedInk)

            if isSecure {
                SecureField("", text: $text)
                    .textFieldStyle(.plain)
            } else {
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? SpeakEasyPalette.tertiarySurface : Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.75), lineWidth: 1)
        )
    }
}

// MARK: - Primary Button
struct GlassPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor,
                                    Color.accentColor.opacity(0.82)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundStyle(.white)
        }
    }
}
