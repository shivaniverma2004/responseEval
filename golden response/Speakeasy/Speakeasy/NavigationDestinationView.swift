//
//  NavigationDestinationView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI
import CoreData

struct NavigationDestinationView: View {
    let selectedProject: ProjectEntity?
    let selectedImages: [UIImage]
    /// Core Data row for the same image shown in `readerImages` when reading from a project (first image in the batch).
    var readerImageEntity: ProjectImageEntity?

    private var readerImages: [UIImage] {
        if selectedProject != nil {
            return Array(selectedImages.prefix(1))
        }

        return selectedImages
    }

    private var projectImageForReader: ProjectImageEntity? {
        selectedProject != nil ? readerImageEntity : nil
    }

    /// Distinguishes reader sessions so SwiftUI does not reuse `@State` across different images or navigations.
    private var readerIdentity: String {
        var parts: [String] = []
        if let oid = readerImageEntity?.objectID {
            parts.append(oid.uriRepresentation().absoluteString)
        }
        if let pid = selectedProject?.objectID {
            parts.append(pid.uriRepresentation().absoluteString)
        }
        parts.append("\(selectedImages.count)")
        let sizeSig = readerImages.map { "\(Int($0.size.width))x\(Int($0.size.height))" }.joined(separator: ",")
        parts.append(sizeSig)
        return parts.joined(separator: "|")
    }

    var body: some View {
        TextProcessingView(images: readerImages, projectImage: projectImageForReader)
            .id(readerIdentity)
    }
}
