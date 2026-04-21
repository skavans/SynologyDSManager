//
//  AppDelegate.swift
//  SynologyDSManager
//

import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {

    func application(_ application: NSApplication, open urls: [URL]) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            DispatchQueue.main.async {

                var torrents: [String] = []

                for url in urls {
                    switch url.scheme {
                    case "synologydsmanager":  // deeplink
                        if url.host == "download" {
                            if let queryItems = URLComponents(string: url.absoluteString)?.queryItems,
                               let downloadURL = queryItems.first(where: { $0.name == "downloadURL" }),
                               let value = downloadURL.value, !value.isEmpty {
                                mainViewController?.downloadByURLFromExtension(URL: value)
                            }
                        }

                    case "file":  // torrent-file to open
                        torrents.append(url.path)

                    default:
                        break
                    }
                }

                if !torrents.isEmpty {
                    mainViewController?.showStoryboardWindowCenteredToMainWindow(
                        storyboardWindowControllerIdentifier: "addDownloadWC"
                    )
                    if let vc = currentViewController as? AddDownloadViewController {
                        vc.torrents = torrents
                        vc.tasksTextView.string = torrents.joined(separator: "\n")
                        vc.tasksTextView.delegate?.textDidChange?(
                            Notification(name: NSNotification.Name("torrentsAdded"))
                        )
                    }
                }
            }
        }
    }
}
