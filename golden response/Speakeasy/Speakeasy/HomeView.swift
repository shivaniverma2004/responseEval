//
//  HomeView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI
import CoreData
import Auth

struct HomeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var selectedTab: AppTab
    @EnvironmentObject private var supabase: SupabaseManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProjectEntity.updatedAt, ascending: false)],
        animation: .snappy
    ) private var projects: FetchedResults<ProjectEntity>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WordEntryEntity.addedAt, ascending: false)],
        animation: .snappy
    ) private var allWords: FetchedResults<WordEntryEntity>
    private let coreData = CoreDataManager.shared
    
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var navigateToPreview = false
    
    private var displayName: String {
        if supabase.isGuestMode {
            return "Learner"
        }
        if let metadata = supabase.currentUser?.userMetadata,
           let name = metadata["display_name"]?.stringValue {
            return name.components(separatedBy: " ").first ?? name
        }
        return "There"
    }
    
    private var recentWords: [WordEntryEntity] {
        Array(allWords.prefix(5))
    }

    private var dailyTarget: Int {
        Int(coreData.getSettings().dailyTarget)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = SpeakEasyLayout.readableContentWidth(
                containerWidth: geometry.size.width,
                maxWidthRegular: 760,
                maxWidthCompact: 640,
                horizontalSizeClass: horizontalSizeClass
            )

            ZStack {
                LinearGradient(
                    colors: [
                        SpeakEasyPalette.backgroundTop,
                        SpeakEasyPalette.backgroundBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        heroSection
                        projectsSection(cardWidth: min(max(contentWidth * 0.46, 190), 280))
                        wordsSection(cardWidth: min(max(contentWidth * 0.28, 120), 180))
                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: contentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(selectedImages: $selectedImages, navigateToPreview: $navigateToPreview)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImages: $selectedImages, showCamera: .constant(false), navigateToPreview: $navigateToPreview)
        }
        .navigationDestination(isPresented: $navigateToPreview) {
            ImagePreviewView(selectedImages: $selectedImages)
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.92),
                            Color.blue.opacity(0.72),
                            Color.cyan.opacity(0.58)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 150, height: 150)
                        .offset(x: 40, y: -30)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 110, height: 110)
                        .offset(x: -25, y: 28)
                }

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hi, \(displayName)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text(supabase.isGuestMode ? "Read, listen, and practice without signing in." : "Turn any image into a cleaner reading experience.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], alignment: .leading, spacing: 10) {
                    statBadge(value: "\(projects.count)", title: "Projects")
                    statBadge(value: "\(recentWords.count)", title: "Words")
                    statBadge(value: "\(dailyTarget)", title: "Goal")
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        heroActionButton(title: "Camera", systemImage: "camera.fill", filled: true) {
                            prepareForNewSelection()
                            showCamera = true
                        }

                        heroActionButton(title: "Gallery", systemImage: "photo.on.rectangle", filled: false) {
                            prepareForNewSelection()
                            showImagePicker = true
                        }
                    }

                    VStack(spacing: 12) {
                        heroActionButton(title: "Camera", systemImage: "camera.fill", filled: true) {
                            prepareForNewSelection()
                            showCamera = true
                        }

                        heroActionButton(title: "Gallery", systemImage: "photo.on.rectangle", filled: false) {
                            prepareForNewSelection()
                            showImagePicker = true
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func statBadge(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.headline.weight(.bold))
            Text(title)
                .font(.caption2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func heroActionButton(title: String, systemImage: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    filled
                        ? AnyShapeStyle(.white)
                        : AnyShapeStyle(.white.opacity(0.16)),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay {
                    if !filled {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.18))
                    }
                }
                .foregroundStyle(filled ? Color.accentColor : .white)
        }
    }

    private func projectsSection(cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                eyebrow: "Projects",
                title: "Recent Reading Sets"
            )

            if projects.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("No projects yet")
                            .font(.headline)
                        Text("Import text from the camera or gallery to build your first project.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(projects.prefix(5), id: \.id) { project in
                            NavigationLink {
                                ProjectDetailView(project: project)
                            } label: {
                                ProjectPreviewCard(project: project, width: cardWidth)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.trailing, 16)
                }
            }
        }
    }

    private func wordsSection(cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                eyebrow: "Practice",
                title: "Recent Words"
            )

            if recentWords.isEmpty {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("No saved words yet")
                            .font(.headline)
                        Text("Tap any word while reading to save it here for later practice.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recentWords, id: \.id) { wordEntry in
                            NavigationLink {
                                WordDetailView(wordEntry: wordEntry)
                            } label: {
                                WordBasketCard(word: wordEntry.word ?? "", width: cardWidth)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func sectionHeader(eyebrow: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(SpeakEasyPalette.ink)

            Text(eyebrow)
                .font(.subheadline)
                .foregroundStyle(SpeakEasyPalette.mutedInk)
        }
    }

    private func prepareForNewSelection() {
        selectedImages.removeAll()
        navigateToPreview = false
    }
}

// MARK: - Project Preview Card

struct ProjectPreviewCard: View {
    @ObservedObject var project: ProjectEntity
    let width: CGFloat
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                if let coverImage = project.coverImageEntity,
                   let image = CoreDataManager.shared.loadImage(from: coverImage) {
                    ProjectThumbnailView(image: image, height: 140, cornerRadius: 12)
                } else {
                    ProjectThumbnailView(image: nil, height: 140, cornerRadius: 12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name ?? "Untitled")
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(SpeakEasyPalette.ink)

                    Text("\(project.imageCount) image\(project.imageCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(SpeakEasyPalette.mutedInk)
                }
            }
        }
        .frame(width: width)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

// MARK: - Word Basket Card

struct WordBasketCard: View {
    let word: String
    let width: CGFloat
    
    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: "text.book.closed.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                Text(word.capitalized)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(SpeakEasyPalette.ink)
            }
            .frame(width: width, height: 92)
        }
    }
}
