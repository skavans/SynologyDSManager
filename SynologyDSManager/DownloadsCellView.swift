//
//  DownloadsCellView.swift
//  SynologyDSManager
//
//  Created by Антон on 14.03.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Cocoa
import Foundation


class DownloadsCellView: NSView, LoadableView {
    
    // MARK: - IBOutlet Properties
    @IBOutlet weak var downloadNameLabel: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var startPauseButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    
    // MARK: - Properties
    
    var mainView: NSView?
    
    // MARK: - Init
    
    init() {
        super.init(frame: NSRect.zero)
        
        _ = load(fromNIBNamed: "DownloadsCellView")
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
