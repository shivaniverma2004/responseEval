//
//  SignUpView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI

struct SignUpView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AuthViewModel()

    @State private var goToDetails = false

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
                    Text("Create Account")
                        .font(.largeTitle.bold())

                    Text("Start your SpeakEasy journey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                GlassCard {
                    VStack(spacing: 16) {

                        GlassTextField(
                            title: "Full Name",
                            text: $vm.name
                        )

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

                        GlassPrimaryButton(
                            title: vm.isLoading ? "Creating…" : "Create Account"
                        ) {
                            Task {
                                let success = await vm.signUp()
                                if success {
                                    goToDetails = true
                                }
                            }
                        }
                        .disabled(vm.isLoading)
                    }
                }

                Button {
                    dismiss()
                } label: {
                    Text("Already have an account? Log in")
                        .font(.footnote)
                }

                Spacer()
            }
            .padding()
        }
        .navigationDestination(isPresented: $goToDetails) {
            AdditionalDetailsView()
        }
    }
}
