//
//  AppDelegate.swift
//  SynologyDSManager
//
//  Created by Антон on 17.01.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func application(_ application: NSApplication, open urls: [URL]) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { timer in
            DispatchQueue.main.async {
                
                var torrents: [String] = []
                
                for url in urls {
                    
                    switch url.scheme {
                    
                    case "synologydsmanager":  // deeplink
                        if "download" == url.host {  // download by URL
                            if let queryItems = URLComponents(string: url.absoluteString)?.queryItems {
                                if let downloadURL = queryItems.filter({$0.name == "downloadURL"}).first {
                                    if downloadURL.value ?? "" != "" {
                                        mainViewController!.downloadByURLFromExtension(URL: downloadURL.value!)
                                    }
                                }
                            }
                        }
                    
                    case "file":  // torrent-file to open
                        torrents.append(url.path)
                        
                    default:
                        break
                    }
                    
                }
                
                if !torrents.isEmpty {
                    mainViewController!.showStoryboardWindowCenteredToMainWindow(storyboardWindowControllerIdentifier: "addDownloadWC")
                    let vc = (currentViewController as! AddDownloadViewController)
                    vc.torrents = torrents
                    vc.tasksTextView.string = torrents.joined(separator: "\n")
                    vc.tasksTextView.delegate?.textDidChange?(Notification(name: NSNotification.Name("torrentsAdded")))
                }
                
            }
            
        })
    }

}
