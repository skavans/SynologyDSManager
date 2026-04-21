//
//  AddDownloadViewController.swift
//  SynologyDSManager
//
//  Created by Антон on 15.03.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Cocoa
import Foundation


class AddDownloadViewController: NSViewController {
    @IBOutlet weak var startDownloadButton: NSButton!
    @IBOutlet var tasksTextView: NSTextView!
    @IBOutlet weak var tasksScrollView: NSScrollView!
    @IBOutlet weak var destinationView: DestinationView!
    
    var torrents: [String] = []
    var urls: [String] = []
    
    @IBAction func startDownloadButtonClicked(_ sender: Any) {
        for t in torrents {
            synologyClient?.startDownload(torrentFilePath: t, destination: self.destinationView.selectedDir)
        }
        for url in urls {
            synologyClient?.startDownload(URL: url, destination: self.destinationView.selectedDir)
        }
        self.view.window?.close()
    }
    
    @IBAction func chooseTorrentFileButtonClicked(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose one or multiple torrent-files";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = true;
        dialog.allowedFileTypes        = ["torrent"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            
            self.tasksTextView.string = dialog.urls.reduce("", {acc, url in
                return acc + "\(url.path)\n"
            }) + self.tasksTextView.string
            
            self.tasksTextView.delegate?.textDidChange?(Notification(name: .init("textChanged")))
            
        } else {
            return
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tasksTextView.delegate = self
        self.destinationView.setSelectionSynchronizeKey(key: "main")
    }
    
    override func viewWillAppear() {
        self.view.window?.styleMask.remove(.fullScreen)
        self.view.window?.styleMask.remove(.miniaturizable)
        self.view.window?.styleMask.remove(.resizable)
        
        self.tasksScrollView.hasHorizontalScroller = true
        tasksTextView.maxSize = NSMakeSize(CGFloat(Float.greatestFiniteMagnitude), CGFloat(Float.greatestFiniteMagnitude))
        tasksTextView.isHorizontallyResizable = true
        tasksTextView.textContainer?.widthTracksTextView = false
        tasksTextView.textContainer?.containerSize = NSMakeSize(CGFloat(Float.greatestFiniteMagnitude), CGFloat(Float.greatestFiniteMagnitude))
    }
}

extension AddDownloadViewController: NSTextViewDelegate {
    
    func textDidChange(_ notification: Notification) {
        torrents = []
        urls = []
                
        func isURL(str: String) -> Bool {
            return (str.hasPrefix("http") || str.hasPrefix("ftp") || str.hasPrefix("ed2k") || str.hasPrefix("magnet"))
        }
        
        for line in self.tasksTextView.string.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed != "" {
                if trimmed.hasPrefix("/") && trimmed.hasSuffix(".torrent") {
                    torrents.append(trimmed)
                } else if isURL(str: trimmed) {
                    urls.append(trimmed)
                }
            }
        }
        
        if torrents.count > 0 || urls.count > 0 {
            startDownloadButton.isEnabled = true
            startDownloadButton.title = "Download \(torrents.count) torrents and \(urls.count) URLs"
            startDownloadButton.highlight(true)
        } else {
            startDownloadButton.isEnabled = false
            startDownloadButton.title = "Add at least one URL or torrent-file"
        }
    }
    
}
