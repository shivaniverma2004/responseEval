//
//  speakEasyApp.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI

@main
struct SpeakEasyApp: App {
    @StateObject private var supabase = SupabaseManager.shared
    @StateObject private var coreData = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            if supabase.isSignedIn || supabase.isGuestMode {
                HomeTabView()
                    .environmentObject(supabase)
                    .environment(\.managedObjectContext, coreData.viewContext)
            } else {
                AuthView()
                    .environmentObject(supabase)
            }
        }
    }
}
