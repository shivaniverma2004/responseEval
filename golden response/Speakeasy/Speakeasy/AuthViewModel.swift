//
//  AuthViewModel.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//


import Foundation
internal import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func signIn() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await SupabaseManager.shared.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signUp() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await SupabaseManager.shared.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password, name: name
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
