import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Binding var showCamera: Bool
    @Binding var navigateToPreview: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if showCamera {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = context.coordinator
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            return imagePicker
        } else {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 0 // 0 means no limit

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        // MARK: - UIImagePickerControllerDelegate for Camera
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            defer {
                picker.dismiss(animated: true)
            }
            if let image = info[.originalImage] as? UIImage {
                Task {
                    await addImage(image)
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        // MARK: - PHPickerViewControllerDelegate for Photo Library
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { return }

            let itemProviders = results.map { $0.itemProvider }
            for item in itemProviders {
                if item.canLoadObject(ofClass: UIImage.self) {
                    item.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                        if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                            return
                        }
                        if let uiImage = image as? UIImage {
                            Task {
                                await self?.addImage(uiImage)
                            }
                        }
                    }
                }
            }
        }

        // MARK: - Helper Method
        @MainActor
        private func addImage(_ image: UIImage) async {
            // Compress the image before adding
            if let compressedData = image.jpegData(compressionQuality: 0.5),
               let compressedImage = UIImage(data: compressedData) {
                self.parent.selectedImages.append(compressedImage)
            } else {
                self.parent.selectedImages.append(image)
            }
            self.parent.navigateToPreview = true
        }
    }
}

struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker(selectedImages: .constant([]), showCamera: .constant(false), navigateToPreview: .constant(false))
    }
}
