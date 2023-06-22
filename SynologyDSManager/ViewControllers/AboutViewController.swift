//
//  DownloadsViewController.swift
//  SynologyDSManager
//
//  Created by Антон on 14.03.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Cocoa
import Foundation


class AboutViewController: NSViewController {
    
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var iconsButton: NSButton!
    
    
    override func viewWillAppear() {
        let iconsButtonAttributedTtitle = NSAttributedString(string: "Icons by icons8", attributes: [
            NSAttributedString.Key.foregroundColor: NSColor.linkColor,
            NSAttributedString.Key.cursor: NSCursor.pointingHand
        ])
        iconsButton.attributedTitle = iconsButtonAttributedTtitle
        
        versionLabel.stringValue = "version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)"
        
        self.view.window?.styleMask.remove(.fullScreen)
        self.view.window?.styleMask.remove(.miniaturizable)
        self.view.window?.styleMask.remove(.resizable)
    }
    
    
    @IBAction func iconsButtonClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://icons8.com")!)
    }
}
