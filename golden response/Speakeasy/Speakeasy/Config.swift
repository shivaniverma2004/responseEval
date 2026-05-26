//
//  Config.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//


import Foundation

enum Config {

    // 🔐 Supabase project URL
    static let supabaseURL = URL(
        string: "https://bgiwtibbeikmhqxvzvyt.supabase.co"
    )!

    // 🔐 Supabase anon public key
    static let supabaseAnonKey = """
    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJnaXd0aWJiZWlrbWhxeHZ6dnl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1NjA2NzcsImV4cCI6MjA4MTEzNjY3N30.mZrdNY867DXXwg_6hNMl7TpeGiGrAK0dUdzfQjQ34Ec
    """

    static let dictionaryBaseURL = URL(
        string: "https://api.dictionaryapi.dev/api/v2/entries/en"
    )!

    static let aiFunctionURL = URL(
        string: "https://bgiwtibbeikmhqxvzvyt.supabase.co/functions/v1/ai"
    )!
}
