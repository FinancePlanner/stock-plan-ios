import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: Context) -> UIViewController {
    log.ui("Preparing Safari presentation for URL: \(url.absoluteString)", level: .info)

    guard isWebURL(url) else {
      let controller = UIAlertController(title: "Invalid Link", message: "This isn’t a valid web URL: \n\n\(url.absoluteString)", preferredStyle: .alert)
      controller.addAction(UIAlertAction(title: "OK", style: .default))
      return controller
    }

    let config = SFSafariViewController.Configuration()
    config.entersReaderIfAvailable = false
    config.barCollapsingEnabled = true

    let safariVC = SFSafariViewController(url: url, configuration: config)
    safariVC.preferredBarTintColor = UIColor.systemBackground
    safariVC.preferredControlTintColor = UIColor.systemBlue
    safariVC.delegate = context.coordinator

    log.ui("SFSafariViewController created successfully", level: .debug)
    return safariVC
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    // No updates needed
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator: NSObject, SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
      log.userAction("Safari view controller finished browsing", level: .info)
    }

    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
      log.ui("Safari initial load completed: success=\(didLoadSuccessfully)", level: .info)
      if !didLoadSuccessfully {
        log.ui("Safari failed to load the page", level: .warning)
      }
    }

    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
      log.ui("Safari redirected to: \(URL.absoluteString)", level: .info)
    }
  }

  private func isWebURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased() else { return false }
    return (scheme == "http" || scheme == "https") && url.host != nil
  }
}
