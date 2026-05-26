//
//  AuthView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI

struct AuthView: View {
    @State private var showSignup = false

    var body: some View {
        NavigationStack {
            LoginView(showSignup: $showSignup)
                .navigationDestination(isPresented: $showSignup) {
                    SignUpView()
                }
        }
    }
}
