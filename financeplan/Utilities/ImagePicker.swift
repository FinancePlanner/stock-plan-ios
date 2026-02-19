import AVFoundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ImagePicker: UIViewControllerRepresentable {
  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: ImagePicker

    init(_ parent: ImagePicker) {
      self.parent = parent
    }

    func imagePickerController(
      _: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let videoURL = info[.mediaURL] as? URL, parent.allowsVideo {
        let tempURL = FileManager.default.temporaryDirectory
          .appendingPathComponent(UUID().uuidString)
          .appendingPathExtension("mp4")
        do {
          try FileManager.default.copyItem(at: videoURL, to: tempURL)
        } catch {
          Task { @MainActor in parent.isPresented = false }
          return
        }
        let thumb = Self.generateThumbnail(for: tempURL)
        Task { @MainActor in
          parent.onMediaSelected(.video(tempURL, thumbnail: thumb ?? Self.placeholderThumbnail))
          parent.isPresented = false
        }
      } else if let image = info[.originalImage] as? UIImage {
        Task { @MainActor in
          parent.onMediaSelected(.image(image))
          parent.isPresented = false
        }
      } else {
        Task { @MainActor in parent.isPresented = false }
      }
    }

    func imagePickerControllerDidCancel(_: UIImagePickerController) {
      parent.isPresented = false
    }

    private static func generateThumbnail(for url: URL) -> UIImage? {
      let asset = AVURLAsset(url: url)
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      generator.maximumSize = CGSize(width: 320, height: 320)
      let time = CMTime(seconds: 0, preferredTimescale: 600)
      guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
      return UIImage(cgImage: cgImage)
    }

    private static var placeholderThumbnail: UIImage {
      let size = CGSize(width: 1, height: 1)
      return UIGraphicsImageRenderer(size: size).image { _ in }
    }
  }

  var sourceType: UIImagePickerController.SourceType = .photoLibrary
  /// When true and sourceType is .camera, user can capture photo or video.
  var allowsVideo: Bool = false

  @Binding var isPresented: Bool
  var onMediaSelected: (SelectedMedia) -> Void
  var onSourceUnavailable: (() -> Void)?

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeUIViewController(context: Context) -> UIViewController {
    guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
      return UnavailableSourceViewController(sourceType: sourceType) {
        isPresented = false
        onSourceUnavailable?()
      }
    }
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = sourceType
    if sourceType == .camera, allowsVideo {
      picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
    }
    return picker
  }

  func updateUIViewController(_: UIViewController, context _: Context) {}
}

private final class UnavailableSourceViewController: UIViewController {
  private let sourceType: UIImagePickerController.SourceType
  private let onDismiss: () -> Void

  init(sourceType: UIImagePickerController.SourceType, onDismiss: @escaping () -> Void) {
    self.sourceType = sourceType
    self.onDismiss = onDismiss
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let message = sourceType == .camera
      ? "Camera is not available on this device (e.g. Simulator). Use Photo or Video to pick from your library."
      : "Photo library is not available."
    let alert = UIAlertController(title: "Not Available", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
      self?.onDismiss()
    })
    present(alert, animated: true)
  }
}
