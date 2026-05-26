//
//  ProfileView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI
import Auth
internal import Combine

struct ProfileView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var supabase: SupabaseManager
    @StateObject private var coreData = CoreDataManager.shared
    @State private var isLoggingOut = false
    @State private var showSettings = false
    
    private var displayName: String {
        if supabase.isGuestMode {
            return "Guest User"
        }
        if let metadata = supabase.currentUser?.userMetadata,
           let name = metadata["display_name"]?.stringValue {
            return name
        }
        return "User"
    }
    
    private var totalAttempts: Int {
        coreData.getTotalPracticeAttempts()
    }
    
    private var averageScore: Double {
        coreData.getAveragePronunciationScore()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = SpeakEasyLayout.readableContentWidth(
                containerWidth: geometry.size.width,
                maxWidthRegular: 760,
                maxWidthCompact: 640,
                horizontalSizeClass: horizontalSizeClass
            )

            ZStack {
                LinearGradient(
                    colors: [SpeakEasyPalette.backgroundTop, SpeakEasyPalette.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader

                        GlassCard {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundStyle(Color.accentColor)
                                    Text("Statistics")
                                        .font(.headline)
                                        .foregroundStyle(SpeakEasyPalette.ink)
                                }
                                
                                VStack(spacing: 16) {
                                    StatRow(
                                        icon: "arrow.clockwise",
                                        title: "Total Practice Attempts",
                                        value: "\(totalAttempts)",
                                        color: .blue
                                    )
                                    
                                    Divider()
                                    
                                    StatRow(
                                        icon: "star.fill",
                                        title: "Average Score",
                                        value: String(format: "%.1f%%", averageScore),
                                        color: .yellow
                                    )
                                }
                            }
                        }
                        
                        GlassCard {
                            VStack(spacing: 12) {
                                if supabase.isGuestMode {
                                    Button {
                                        supabase.exitGuestMode()
                                    } label: {
                                        settingsRow(icon: "person.badge.key.fill", title: "Sign In or Create Account")
                                    }

                                    Divider()
                                }

                                Button {
                                    showSettings = true
                                } label: {
                                    settingsRow(icon: "gearshape.fill", title: "Settings")
                                }
                                
                                Divider()
                                
                                if supabase.isGuestMode {
                                    Button(role: .destructive) {
                                        supabase.exitGuestMode()
                                    } label: {
                                        settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Exit Guest Mode", tint: .red, isDestructive: true)
                                    }
                                } else {
                                    Button(role: .destructive) {
                                        Task {
                                            isLoggingOut = true
                                            try? await supabase.signOut()
                                            isLoggingOut = false
                                        }
                                    } label: {
                                        settingsRow(icon: "rectangle.portrait.and.arrow.right", title: isLoggingOut ? "Logging Out…" : "Log Out", tint: .red, isDestructive: true)
                                    }
                                    .disabled(isLoggingOut)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: contentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var profileHeader: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("PROFILE")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(SpeakEasyPalette.mutedInk)

                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.blue.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 84, height: 84)
                        Image(systemName: "person.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(SpeakEasyPalette.ink)
                        Text(supabase.isGuestMode ? "Your progress stays on this device." : (supabase.currentUser?.email ?? ""))
                            .font(.subheadline)
                            .foregroundStyle(SpeakEasyPalette.mutedInk)
                    }
                }
            }
        }
    }

    private func settingsRow(icon: String, title: String, tint: Color = Color.accentColor, isDestructive: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
                .foregroundStyle(isDestructive ? .red : SpeakEasyPalette.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = Color.accentColor
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SpeakEasyPalette.ink)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundStyle(SpeakEasyPalette.ink)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coreData = CoreDataManager.shared
    @State private var dailyTarget: Int = 10
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Daily Target: \(dailyTarget) words", value: $dailyTarget, in: 1...100)
                        .onChange(of: dailyTarget) { _, newValue in
                            coreData.updateDailyTarget(Int16(newValue))
                        }
                } header: {
                    Text("Learning Goals")
                } footer: {
                    Text("Set your daily word learning target")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy & Data")
                            .font(.headline)
                        Text("All learning data is stored locally on your device. Dictionary and AI features require an internet connection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Privacy")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            let settings = coreData.getSettings()
            dailyTarget = Int(settings.dailyTarget)
        }
    }
}
