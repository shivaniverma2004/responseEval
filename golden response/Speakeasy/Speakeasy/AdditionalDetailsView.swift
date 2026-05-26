//
//  AdditionalDetailsView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//


import SwiftUI

struct AdditionalDetailsView: View {

    @EnvironmentObject private var supabase: SupabaseManager
    @StateObject private var coreData = CoreDataManager.shared
    @State private var englishLevel = "Beginner"

    let levels = ["Beginner", "Intermediate", "Advanced", "Fluent"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {

                Spacer()

                VStack(spacing: 8) {
                    Text("Tell us about you")
                        .font(.largeTitle.bold())

                    Text("This helps personalize your experience")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                GlassCard {
                    Picker("English Level", selection: $englishLevel) {
                        ForEach(levels, id: \.self) { level in
                            Text(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                GlassPrimaryButton(title: "Finish") {
                    coreData.markOnboardingCompleted()
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}
