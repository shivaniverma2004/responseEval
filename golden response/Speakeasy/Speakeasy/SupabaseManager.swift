//
//  SupabaseManager.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//


import Foundation
import Supabase
import SwiftUI
internal import Combine

@MainActor
final class SupabaseManager: ObservableObject {

    static let shared = SupabaseManager()
    private static let guestModeKey = "SpeakEasyGuestModeEnabled"

    let client: SupabaseClient

    @Published var currentUser: User?
    @Published var isSignedIn: Bool = false
    @Published var isGuestMode: Bool

    private init() {
        isGuestMode = UserDefaults.standard.bool(forKey: Self.guestModeKey)
        client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )

        // Restore session on app launch
        Task {
            await restoreSession()
        }
    }

    // MARK: - Session Restore
    func restoreSession() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isSignedIn = true
            self.setGuestMode(false)
        } catch {
            self.currentUser = nil
            self.isSignedIn = false
        }
    }

    // MARK: - Auth Actions

    func signUp(email: String, password: String, name: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "display_name": AnyJSON.string(name)
            ]
        )

        self.currentUser = response.user
        self.isSignedIn = true
        self.setGuestMode(false)
    }


    func signIn(email: String, password: String) async throws {
        let result = try await client.auth.signIn(
            email: email,
            password: password
        )
        self.currentUser = result.user
        self.isSignedIn = true
        self.setGuestMode(false)
    }

    func continueAsGuest() {
        currentUser = nil
        isSignedIn = false
        setGuestMode(true)
    }

    func exitGuestMode() {
        setGuestMode(false)
    }

    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUser = nil
        self.isSignedIn = false
        self.setGuestMode(false)
    }

    private func setGuestMode(_ enabled: Bool) {
        isGuestMode = enabled
        UserDefaults.standard.set(enabled, forKey: Self.guestModeKey)
    }
}
