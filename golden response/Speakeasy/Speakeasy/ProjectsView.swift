//
//  ProjectsView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI
import CoreData

struct ProjectsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProjectEntity.updatedAt, ascending: false)],
        animation: .snappy
    ) private var projects: FetchedResults<ProjectEntity>
    private let coreData = CoreDataManager.shared
    @State private var projectPendingDeletion: ProjectEntity?
    @State private var projectPendingRename: ProjectEntity?
    @State private var projectNameDraft = ""

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: horizontalSizeClass == .regular ? 240 : 160), spacing: 16)]
    }
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = SpeakEasyLayout.readableContentWidth(
                containerWidth: geometry.size.width,
                maxWidthRegular: 860,
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
                
                if projects.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 72))
                            .foregroundStyle(.secondary.opacity(0.6))
                        
                        Text("No projects yet")
                            .font(.title2.bold())
                        
                        Text("Capture images to create your first project")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(projects, id: \.id) { project in
                                    NavigationLink {
                                        ProjectDetailView(project: project)
                                    } label: {
                                        ProjectCard(project: project)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button {
                                            projectPendingRename = project
                                            projectNameDraft = project.name ?? ""
                                        } label: {
                                            Label("Rename Project", systemImage: "pencil")
                                        }

                                        Button(role: .destructive) {
                                            projectPendingDeletion = project
                                        } label: {
                                            Label("Delete Project", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: contentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Delete this project?",
            isPresented: Binding(
                get: { projectPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        projectPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Project", role: .destructive) {
                if let projectPendingDeletion {
                    coreData.deleteProject(projectPendingDeletion)
                }
                projectPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                projectPendingDeletion = nil
            }
        } message: {
            Text("This will permanently remove the project and all images inside it.")
        }
        .alert(
            "Rename Project",
            isPresented: Binding(
                get: { projectPendingRename != nil },
                set: { isPresented in
                    if !isPresented {
                        projectPendingRename = nil
                    }
                }
            )
        ) {
            TextField("Project name", text: $projectNameDraft)
            Button("Save") {
                if let projectPendingRename {
                    coreData.renameProject(projectPendingRename, name: projectNameDraft)
                }
                projectPendingRename = nil
            }
            Button("Cancel", role: .cancel) {
                projectPendingRename = nil
            }
        }
    }

}

// MARK: - Project Card

struct ProjectCard: View {
    @ObservedObject var project: ProjectEntity
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                if let coverImage = project.coverImageEntity,
                   let image = CoreDataManager.shared.loadImage(from: coverImage) {
                    ProjectThumbnailView(image: image, height: 160, cornerRadius: 12)
                } else {
                    ProjectThumbnailView(image: nil, height: 160, cornerRadius: 12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name ?? "Untitled")
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(SpeakEasyPalette.ink)
                    
                    Text("\(project.imageCount) image\(project.imageCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(SpeakEasyPalette.mutedInk)
                }
            }
        }
    }
}

// MARK: - Project Detail View

struct ProjectDetailView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var project: ProjectEntity
    @Environment(\.dismiss) private var dismiss
    private let coreData = CoreDataManager.shared
    @State private var showDeleteProjectConfirmation = false
    @State private var showDeleteImagesConfirmation = false
    @State private var showRenameProject = false
    @State private var isSelectingImages = false
    @State private var selectedImageIDs: Set<NSManagedObjectID> = []
    @State private var projectNameDraft = ""
    
    private var images: [ProjectImageEntity] {
        project.sortedImages
    }

    private var imageGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: horizontalSizeClass == .regular ? 220 : 150), spacing: 14)]
    }
    
    var body: some View {
        Group {
            if images.isEmpty {
                ContentUnavailableView {
                    Label("No Images", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("This project doesn't have any images right now.")
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: imageGridColumns, spacing: 14) {
                        ForEach(images, id: \.id) { imageEntity in
                            if isSelectingImages {
                                Button {
                                    toggleSelection(for: imageEntity)
                                } label: {
                                    ProjectImageTile(
                                        imageEntity: imageEntity,
                                        isSelected: selectedImageIDs.contains(imageEntity.objectID)
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink {
                                    if let image = coreData.loadImage(from: imageEntity) {
                                        TextProcessingView(images: [image], projectImage: imageEntity)
                                            .id(imageEntity.objectID)
                                    }
                                } label: {
                                    ProjectImageTile(imageEntity: imageEntity, isSelected: false)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(
            LinearGradient(
                colors: [SpeakEasyPalette.backgroundTop, SpeakEasyPalette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle(project.name ?? "Project")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if isSelectingImages {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            isSelectingImages = false
                            selectedImageIDs.removeAll()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteImagesConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selectedImageIDs.isEmpty)
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            projectNameDraft = project.name ?? ""
                            showRenameProject = true
                        } label: {
                            Label("Rename Project", systemImage: "pencil")
                        }

                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                isSelectingImages = true
                            }
                        } label: {
                            Label("Select Images", systemImage: "checkmark.circle")
                        }

                        Button(role: .destructive) {
                            showDeleteProjectConfirmation = true
                        } label: {
                            Label("Delete Project", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .alert("Rename Project", isPresented: $showRenameProject) {
            TextField("Project name", text: $projectNameDraft)
            Button("Save") {
                coreData.renameProject(project, name: projectNameDraft)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose a short name that helps you find this set later.")
        }
        .confirmationDialog(
            "Remove selected images?",
            isPresented: $showDeleteImagesConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove \(selectedImageIDs.count) Image\(selectedImageIDs.count == 1 ? "" : "s")", role: .destructive) {
                let imagesToDelete = images.filter { selectedImageIDs.contains($0.objectID) }
                coreData.deleteImages(imagesToDelete)
                selectedImageIDs.removeAll()
                isSelectingImages = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Selected images will be removed from this project.")
        }
        .confirmationDialog(
            "Delete this project?",
            isPresented: $showDeleteProjectConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Project", role: .destructive) {
                coreData.deleteProject(project)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the project and all images inside it.")
        }
    }

    private func toggleSelection(for imageEntity: ProjectImageEntity) {
        if selectedImageIDs.contains(imageEntity.objectID) {
            selectedImageIDs.remove(imageEntity.objectID)
        } else {
            selectedImageIDs.insert(imageEntity.objectID)
        }
    }
}

private struct ProjectImageTile: View {
    let imageEntity: ProjectImageEntity
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GlassCard {
                ProjectThumbnailView(
                    image: CoreDataManager.shared.loadImage(from: imageEntity),
                    height: 190,
                    cornerRadius: 18
                )
            }

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white, Color.accentColor)
                    .padding(12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Project image")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Double tap to remove this image from the selection" : "Double tap to select this image")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}
