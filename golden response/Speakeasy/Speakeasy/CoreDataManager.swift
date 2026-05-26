//
//  CoreDataManager.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import Foundation
import CoreData
import UIKit
import SwiftUI
internal import Combine

@MainActor
final class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    var objectWillChange = ObservableObjectPublisher()
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "SpeakEasyModel")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        normalizeStoredWordsIfNeeded()
    }
    
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Project Management
    
    func createProject(name: String) -> ProjectEntity? {
        let project = ProjectEntity(context: viewContext)
        project.id = UUID()
        project.name = name
        project.createdAt = Date()
        project.updatedAt = Date()
        save()
        return project
    }
    
    func fetchProjects() -> [ProjectEntity] {
        let request: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ProjectEntity.updatedAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch projects: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteProject(_ project: ProjectEntity) {
        let projectImages = (project.images?.allObjects as? [ProjectImageEntity]) ?? []
        for imageEntity in projectImages {
            deleteImageFile(for: imageEntity)
        }
        viewContext.delete(project)
        save()
    }

    func renameProject(_ project: ProjectEntity, name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        project.name = trimmedName
        project.updatedAt = Date()
        save()
        objectWillChange.send()
    }
    
    // MARK: - Project Image Management
    
    func addImage(to project: ProjectEntity, image: UIImage) -> ProjectImageEntity? {
        let imageEntity = ProjectImageEntity(context: viewContext)
        imageEntity.id = UUID()
        imageEntity.createdAt = Date()
        
        // Save image to FileManager
        let fileName = "\(imageEntity.id!.uuidString).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(fileName)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            try? imageData.write(to: filePath)
            imageEntity.imageFilePath = fileName
        }
        
        imageEntity.project = project
        project.updatedAt = Date()
        save()
        return imageEntity
    }
    
    func loadImage(from imageEntity: ProjectImageEntity) -> UIImage? {
        guard let fileName = imageEntity.imageFilePath else { return nil }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(fileName)
        
        if let imageData = try? Data(contentsOf: filePath) {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    func updateImageText(_ imageEntity: ProjectImageEntity, text: String, languageTag: String = "en") {
        imageEntity.extractedText = text
        imageEntity.languageTag = languageTag
        imageEntity.project?.updatedAt = Date()
        save()
    }
    
    func deleteImage(_ imageEntity: ProjectImageEntity) {
        deleteImageFile(for: imageEntity)
        
        viewContext.delete(imageEntity)
        save()
    }

    func deleteImages(_ imageEntities: [ProjectImageEntity]) {
        let parentProject = imageEntities.first?.project

        for imageEntity in imageEntities {
            deleteImageFile(for: imageEntity)
            viewContext.delete(imageEntity)
        }

        parentProject?.updatedAt = Date()
        save()
        objectWillChange.send()
    }
    
    // MARK: - Word Entry Management
    
    func addWordToBasket(_ word: String) -> WordEntryEntity? {
        let normalizedWord = normalizedWord(from: word)
        guard !normalizedWord.isEmpty else { return nil }
        
        // Check if word already exists
        let request: NSFetchRequest<WordEntryEntity> = WordEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "word == %@", normalizedWord)
        
        if let existing = try? viewContext.fetch(request).first {
            return existing
        }
        
        let wordEntry = WordEntryEntity(context: viewContext)
        wordEntry.id = UUID()
        wordEntry.word = normalizedWord
        wordEntry.addedAt = Date()
        wordEntry.lastScore = 0
        wordEntry.attempts = 0
        save()
        return wordEntry
    }
    
    func fetchWordEntries() -> [WordEntryEntity] {
        normalizeStoredWordsIfNeeded()

        let request: NSFetchRequest<WordEntryEntity> = WordEntryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WordEntryEntity.addedAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch word entries: \(error.localizedDescription)")
            return []
        }
    }
    
    func updateWordScore(_ word: String, score: Int) {
        let normalizedWord = normalizedWord(from: word)
        guard !normalizedWord.isEmpty else { return }

        let request: NSFetchRequest<WordEntryEntity> = WordEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "word == %@", normalizedWord)
        
        let wordEntry: WordEntryEntity
        if let existing = try? viewContext.fetch(request).first {
            wordEntry = existing
        } else {
            // Create new word entry if it doesn't exist
            wordEntry = WordEntryEntity(context: viewContext)
            wordEntry.id = UUID()
            wordEntry.word = normalizedWord
            wordEntry.addedAt = Date()
            wordEntry.lastScore = 0
            wordEntry.attempts = 0
        }
        
        wordEntry.lastScore = Int16(score)
        wordEntry.attempts += 1
        
        // Create practice attempt
        let attempt = PracticeAttemptEntity(context: viewContext)
        attempt.id = UUID()
        attempt.score = Int16(score)
        attempt.timestamp = Date()
        attempt.wordEntry = wordEntry
        
        save()
        objectWillChange.send()
    }
    
    func deleteWordEntry(_ wordEntry: WordEntryEntity) {
        viewContext.delete(wordEntry)
        save()
    }
    
    // MARK: - Settings Management
    
    func getSettings() -> SettingsEntity {
        let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        
        if let settings = try? viewContext.fetch(request).first {
            return settings
        }
        
        // Create default settings
        let settings = SettingsEntity(context: viewContext)
        settings.dailyTarget = 10
        settings.onboardingCompleted = false
        settings.themePreferences = "system"
        save()
        return settings
    }
    
    func updateDailyTarget(_ target: Int16) {
        let settings = getSettings()
        settings.dailyTarget = target
        save()
    }
    
    func markOnboardingCompleted() {
        let settings = getSettings()
        settings.onboardingCompleted = true
        save()
    }
    
    // MARK: - Statistics
    
    func getTotalPracticeAttempts() -> Int {
        let request: NSFetchRequest<PracticeAttemptEntity> = PracticeAttemptEntity.fetchRequest()
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    func getAveragePronunciationScore() -> Double {
        let request: NSFetchRequest<PracticeAttemptEntity> = PracticeAttemptEntity.fetchRequest()
        guard let attempts = try? viewContext.fetch(request), !attempts.isEmpty else {
            return 0.0
        }
        
        let total = attempts.reduce(0) { $0 + Int($1.score) }
        return Double(total) / Double(attempts.count)
    }

    private func normalizedWord(from rawWord: String) -> String {
        let allowedCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "'-"))
        let scalars = rawWord.unicodeScalars.filter { allowedCharacters.contains($0) }
        return String(String.UnicodeScalarView(scalars))
            .trimmingCharacters(in: CharacterSet(charactersIn: "'-"))
            .lowercased()
    }

    private func deleteImageFile(for imageEntity: ProjectImageEntity) {
        guard let fileName = imageEntity.imageFilePath else { return }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: filePath)
    }

    private func normalizeStoredWordsIfNeeded() {
        let request: NSFetchRequest<WordEntryEntity> = WordEntryEntity.fetchRequest()

        guard let entries = try? viewContext.fetch(request) else { return }

        var canonicalEntries: [String: WordEntryEntity] = [:]
        var didMutate = false

        for entry in entries {
            let currentWord = entry.word ?? ""
            let normalized = normalizedWord(from: currentWord)

            guard !normalized.isEmpty else {
                viewContext.delete(entry)
                didMutate = true
                continue
            }

            if let existing = canonicalEntries[normalized], existing != entry {
                existing.lastScore = max(existing.lastScore, entry.lastScore)
                existing.attempts += entry.attempts

                if let duplicateAttempts = entry.practiceAttempts?.allObjects as? [PracticeAttemptEntity] {
                    for attempt in duplicateAttempts {
                        attempt.wordEntry = existing
                    }
                }

                if let existingAddedAt = existing.addedAt, let entryAddedAt = entry.addedAt {
                    existing.addedAt = min(existingAddedAt, entryAddedAt)
                } else if existing.addedAt == nil {
                    existing.addedAt = entry.addedAt
                }

                viewContext.delete(entry)
                didMutate = true
                continue
            }

            canonicalEntries[normalized] = entry

            if currentWord != normalized {
                entry.word = normalized
                didMutate = true
            }
        }

        if didMutate {
            save()
            objectWillChange.send()
        }
    }
}
