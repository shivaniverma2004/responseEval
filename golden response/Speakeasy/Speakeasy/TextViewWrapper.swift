import SwiftUI
import UIKit

struct TextViewWrapper: UIViewRepresentable {
    @Binding var text: String
    @Binding var fontSize: CGFloat
    @Binding var lineSpacing: CGFloat
    @Binding var selectedWord: String
    @Binding var showWordOptions: Bool

    var letterSpacing: CGFloat = 0
    var alignment: TextProcessingView.TextAlignment = .leading
    var theme: TextProcessingView.Theme = .system
    var onWordTap: ((String) -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        textView.isEditable = false
        textView.isSelectable = true

        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.textContainer.lineFragmentPadding = 0

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tapGesture.cancelsTouchesInView = false
        textView.addGestureRecognizer(tapGesture)

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = (lineSpacing - 1) * fontSize

        switch alignment {
        case .leading:
            paragraphStyle.alignment = .left
        case .center:
            paragraphStyle.alignment = .center
        case .justified:
            paragraphStyle.alignment = .justified
        }

        let textColor: UIColor
        switch theme {
        case .light, .highContrast:
            textColor = .black
        case .dark:
            textColor = .white
        case .system:
            textColor = .label
        }

        uiView.textColor = textColor  

        uiView.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize),
                .paragraphStyle: paragraphStyle,
                .kern: letterSpacing,
                .foregroundColor: textColor
            ]
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject {
        let parent: TextViewWrapper

        init(parent: TextViewWrapper) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            let location = gesture.location(in: textView)

            if let position = textView.closestPosition(to: location),
               let range = textView.tokenizer.rangeEnclosingPosition(
                    position,
                    with: .word,
                    inDirection: UITextDirection.storage(.forward)
               ),
               let word = textView.text(in: range) {

                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                parent.selectedWord = word
                parent.showWordOptions = true
                parent.onWordTap?(word)
            }
        }
    }
}
