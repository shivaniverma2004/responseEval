//
//  ImagePreviewView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI
import CoreData

struct ImagePreviewView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    @State private var showProjectSelection = false
    @State private var navigateToTextProcessing = false
    @State private var selectedProject: ProjectEntity?
    @State private var readerFocusImageEntity: ProjectImageEntity?
    @State private var showActionSheet = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let contentWidth = SpeakEasyLayout.readableContentWidth(
                    containerWidth: geometry.size.width,
                    maxWidthRegular: 820,
                    maxWidthCompact: 680,
                    horizontalSizeClass: horizontalSizeClass
                )

                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    if selectedImages.isEmpty {
                        ContentUnavailableView {
                            Label("No Images Selected", systemImage: "photo.on.rectangle.angled")
                        } description: {
                            Text("Choose one or more images to review before reading or saving them to a project.")
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                previewHeader
                                
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    GlassCard {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Text("Image \(index + 1)")
                                                    .font(.headline)
                                                Spacer()
                                                Button(role: .destructive) {
                                                    removeImage(at: index)
                                                } label: {
                                                    Image(systemName: "trash")
                                                        .font(.body.weight(.semibold))
                                                        .foregroundStyle(.red)
                                                        .frame(width: 32, height: 32)
                                                        .background(Color.red.opacity(0.12), in: Circle())
                                                }
                                                .accessibilityLabel("Remove image \(index + 1)")
                                                .accessibilityHint("Removes this image from the review screen")
                                            }
                                            
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: .infinity)
                                                .frame(maxHeight: horizontalSizeClass == .regular ? 420 : 320)
                                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: contentWidth, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 150)
                        }
                    }
                }
            }
            .navigationTitle("Review Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                if !selectedImages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showActionSheet = true
                        } label: {
                            Label("Add Image", systemImage: "plus")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !selectedImages.isEmpty {
                    bottomActionBar
                }
            }
            .sheet(isPresented: $showProjectSelection) {
                ProjectSelectionView(
                    selectedImages: $selectedImages,
                    selectedProject: $selectedProject,
                    navigateToTextProcessing: $navigateToTextProcessing,
                    readerFocusImageEntity: $readerFocusImageEntity
                )
            }
            .navigationDestination(isPresented: $navigateToTextProcessing) {
                NavigationDestinationView(
                    selectedProject: selectedProject,
                    selectedImages: selectedImages,
                    readerImageEntity: readerFocusImageEntity
                )
            }
            .confirmationDialog("Add Image", isPresented: $showActionSheet, titleVisibility: .visible) {
                Button("Take Photo") {
                    showCamera = true
                }
                Button("Choose from Gallery") {
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(selectedImages: $selectedImages, navigateToPreview: .constant(false))
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    selectedImages: $selectedImages,
                    showCamera: .constant(false),
                    navigateToPreview: .constant(false)
                )
            }
        }
    }

    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(selectedImages.count) image\(selectedImages.count == 1 ? "" : "s") selected")
                .font(.title3.weight(.semibold))
            Text("Review your images, remove any you don't need, or add more before continuing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var bottomActionBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                saveToProjectButton
                readNowButton
            }

        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var readNowButton: some View {
        GlassPrimaryButton(title: "Read Now") {
            selectedProject = nil
            readerFocusImageEntity = nil
            navigateToTextProcessing = true
        }
    }

    private var saveToProjectButton: some View {
        Button {
            showProjectSelection = true
        } label: {
            Label("Save to Project", systemImage: "folder.badge.plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .foregroundStyle(.primary)
        }
    }

    private func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
        if selectedImages.isEmpty {
            dismiss()
        }
    }
}

// MARK: - Project Selection View

struct ProjectSelectionView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var selectedImages: [UIImage]
    @Binding var selectedProject: ProjectEntity?
    @Binding var navigateToTextProcessing: Bool
    @Binding var readerFocusImageEntity: ProjectImageEntity?
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProjectEntity.updatedAt, ascending: false)],
        animation: .snappy
    ) private var projects: FetchedResults<ProjectEntity>
    @FocusState private var isNamingProject: Bool
    private let coreData = CoreDataManager.shared
    @State private var newProjectName = ""
    @State private var showNewProjectField = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let contentWidth = SpeakEasyLayout.readableContentWidth(
                    containerWidth: geometry.size.width,
                    maxWidthRegular: 760,
                    maxWidthCompact: 640,
                    horizontalSizeClass: horizontalSizeClass
                )

                ZStack {
                    LinearGradient(
                        colors: [SpeakEasyPalette.backgroundTop, SpeakEasyPalette.backgroundBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Save \(selectedImages.count) image\(selectedImages.count == 1 ? "" : "s")")
                                        .font(.headline)
                                        .foregroundStyle(SpeakEasyPalette.ink)
                                    Text("Choose an existing project or create a new one. Your images will be added right away.")
                                        .font(.subheadline)
                                        .foregroundStyle(SpeakEasyPalette.mutedInk)
                                }
                            }

                            GlassCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Existing Projects")
                                        .font(.headline)
                                        .foregroundStyle(SpeakEasyPalette.ink)

                                    if projects.isEmpty {
                                        Text("No projects yet")
                                            .font(.subheadline)
                                            .foregroundStyle(SpeakEasyPalette.mutedInk)
                                    } else {
                                        ForEach(Array(projects.enumerated()), id: \.element.objectID) { index, project in
                                            Button {
                                                selectedProject = project
                                                saveImages()
                                            } label: {
                                                HStack(spacing: 12) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(project.name ?? "Untitled")
                                                            .font(.headline)
                                                            .foregroundStyle(SpeakEasyPalette.ink)
                                                        Text("\(project.imageCount) image\(project.imageCount == 1 ? "" : "s")")
                                                            .font(.caption)
                                                            .foregroundStyle(SpeakEasyPalette.mutedInk)
                                                    }
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .font(.caption.weight(.semibold))
                                                        .foregroundStyle(.tertiary)
                                                }
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)

                                            if index < projects.count - 1 {
                                                Divider()
                                            }
                                        }
                                    }
                                }
                            }

                            GlassCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Text("New Project")
                                            .font(.headline)
                                            .foregroundStyle(SpeakEasyPalette.ink)
                                        Spacer()
                                        if !showNewProjectField {
                                            Button {
                                                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                                    showNewProjectField = true
                                                }
                                            } label: {
                                                Label("Create", systemImage: "plus")
                                            }
                                        }
                                    }

                                    if showNewProjectField {
                                        TextField("Project Name", text: $newProjectName)
                                            .focused($isNamingProject)
                                            .textInputAutocapitalization(.words)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 12)
                                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                                        GlassPrimaryButton(title: "Create and Save") {
                                            createAndSave()
                                        }
                                        .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    } else {
                                        Text("Start a fresh reading set if these images belong in a new project.")
                                            .font(.subheadline)
                                            .foregroundStyle(SpeakEasyPalette.mutedInk)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: contentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Save to Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: showNewProjectField) { _, isVisible in
                if isVisible {
                    isNamingProject = true
                }
            }
        }
    }
    
    private func saveImages() {
        guard let project = selectedProject else { return }

        readerFocusImageEntity = nil
        var firstEntity: ProjectImageEntity?
        for image in selectedImages {
            if let entity = coreData.addImage(to: project, image: image) {
                if firstEntity == nil {
                    firstEntity = entity
                }
            }
        }
        readerFocusImageEntity = firstEntity

        dismiss()
        navigateToTextProcessing = true
    }
    
    private func createAndSave() {
        let trimmedName = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let project = coreData.createProject(name: trimmedName) {
            selectedProject = project
            saveImages()
        }
    }
}
