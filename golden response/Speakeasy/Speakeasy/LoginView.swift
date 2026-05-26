//
//  LoginView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//


import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var supabase: SupabaseManager

    @StateObject private var vm = AuthViewModel()
    @Binding var showSignup: Bool

    var body: some View {
        ZStack {
            // Apple-style subtle background
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
                    Text("SpeakEasy")
                        .font(.largeTitle.bold())

                    Text("Read. Listen. Practice.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                GlassCard {
                    VStack(spacing: 16) {
                        GlassTextField(
                            title: "Email",
                            text: $vm.email
                        )

                        GlassTextField(
                            title: "Password",
                            text: $vm.password,
                            isSecure: true
                        )

                        if let error = vm.errorMessage {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }

                        GlassPrimaryButton(title: vm.isLoading ? "Signing In…" : "Log In") {
                            Task {
                                _ = await vm.signIn()
                            }
                        }
                        .disabled(vm.isLoading)
                    }
                }

                Button {
                    showSignup = true
                } label: {
                    Text("Don’t have an account? Sign up")
                        .font(.footnote)
                }

                Button {
                    supabase.continueAsGuest()
                } label: {
                    Text("Skip for Now")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                Spacer()
            }
            .padding()
        }
    }
}
