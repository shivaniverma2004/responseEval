//
//  BackendService.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import Foundation
internal import Combine

struct DictionaryResponse: Codable {
    let word: String
    let phonetics: [Phonetic]?
    let definitions: [Definition]
    let examples: [String]?
}

struct Phonetic: Codable {
    let text: String?
    let audio: String?
}

struct Definition: Codable {
    let partOfSpeech: String
    let meaning: String
    let example: String?
}

private struct DictionaryAPIEntry: Codable {
    let word: String
    let phonetics: [DictionaryAPIPhonetic]?
    let meanings: [DictionaryAPIMeaning]
}

private struct DictionaryAPIPhonetic: Codable {
    let text: String?
    let audio: String?
}

private struct DictionaryAPIMeaning: Codable {
    let partOfSpeech: String
    let definitions: [DictionaryAPIDefinition]
}

private struct DictionaryAPIDefinition: Codable {
    let definition: String
    let example: String?
}

private struct AIFunctionRequest: Encodable {
    let task: String
    let text: String?
    let sentence: String?
    let word: String?
    let level: String
}

private struct AIFunctionResponse: Decodable {
    let result: String?
    let error: String?
}

enum BackendServiceError: LocalizedError {
    case missingAIConfiguration
    case emptyAIResponse
    case dictionaryNotFound

    var errorDescription: String? {
        switch self {
        case .missingAIConfiguration:
            return "The AI service is not configured yet."
        case .emptyAIResponse:
            return "The AI service returned an empty response."
        case .dictionaryNotFound:
            return "No dictionary meaning was found for this word."
        }
    }
}

@MainActor
final class BackendService: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    static let shared = BackendService()

    private init() {}

    // MARK: - Dictionary Lookup

    func lookupWord(_ word: String) async throws -> DictionaryResponse {
        let cleanWord = normalizedLookupWord(from: word)
        guard !cleanWord.isEmpty else {
            throw BackendServiceError.dictionaryNotFound
        }

        let encodedWord = cleanWord.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleanWord
        let url = Config.dictionaryBaseURL.appendingPathComponent(encodedWord)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw BackendServiceError.dictionaryNotFound
            }
            throw URLError(.badServerResponse)
        }

        let entries = try JSONDecoder().decode([DictionaryAPIEntry].self, from: data)
        guard let entry = entries.first else {
            throw BackendServiceError.dictionaryNotFound
        }

        let definitions = entry.meanings.flatMap { meaning in
            meaning.definitions.map { definition in
                Definition(
                    partOfSpeech: meaning.partOfSpeech,
                    meaning: definition.definition,
                    example: definition.example
                )
            }
        }

        return DictionaryResponse(
            word: entry.word,
            phonetics: entry.phonetics?.map { Phonetic(text: $0.text, audio: $0.audio) },
            definitions: definitions,
            examples: definitions.compactMap(\.example)
        )
    }

    // MARK: - AI Features

    func summarizeText(_ text: String) async throws -> String {
        try await performAITask(task: "summarize_text", text: text)
    }

    func simplifyText(_ text: String) async throws -> String {
        try await performAITask(task: "simplify_text", text: text)
    }

    func generateQuiz(_ text: String) async throws -> String {
        try await performAITask(task: "generate_quiz", text: text)
    }

    func explainGrammar(_ text: String) async throws -> String {
        try await performAITask(task: "explain_grammar", text: text)
    }

    private func performAITask(task: String, text: String) async throws -> String {
        let requestBody = AIFunctionRequest(
            task: task,
            text: text,
            sentence: nil,
            word: nil,
            level: "beginner"
        )

        var request = URLRequest(url: Config.aiFunctionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let aiResponse = try JSONDecoder().decode(AIFunctionResponse.self, from: data)
        guard (200...299).contains(httpResponse.statusCode) else {
            if let error = aiResponse.error, !error.isEmpty {
                throw NSError(domain: "SpeakEasyAI", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: error
                ])
            }
            throw URLError(.badServerResponse)
        }

        if let result = aiResponse.result?.trimmingCharacters(in: .whitespacesAndNewlines),
           !result.isEmpty {
            return result
        }

        throw BackendServiceError.emptyAIResponse
    }

    private func normalizedLookupWord(from rawWord: String) -> String {
        let allowedCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "'-"))
        let scalars = rawWord.unicodeScalars.filter { allowedCharacters.contains($0) }
        return String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: CharacterSet(charactersIn: "'-"))
            .lowercased()
    }
}
