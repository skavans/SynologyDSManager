//
//  DestinationView.swift
//  SynologyDSManager
//
//  Created by Антон on 22.04.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Foundation
import Cocoa

import SwiftyJSON


class DestinationView: NSView, LoadableView {
    @IBOutlet var topView: NSView!
    @IBOutlet weak var destinationsSelector: NSPopUpButton!
    
    var mainView: NSView?
    
    public var selectedDir: String? = nil
    
    private var selectionSaveKey: String? = nil
    
    
    private var values: [(String, String?)] = [
        ("Download Station default", nil),
        ("SEPARATOR", nil),
        ("Other...", nil)
    ]
    
        
    init() {
        super.init(frame: NSRect.zero)
        _ = load(fromNIBNamed: "DestinationView")
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _ = load(fromNIBNamed: "DestinationView")
        setup()
    }
    
    public func setSelectionSynchronizeKey(key: String) {
        self.selectionSaveKey = key
        
        if let selectedTitle = userDefaults.string(forKey: "destinationSelectedTitle_\(self.selectionSaveKey!)") {
            self.destinationsSelector.selectItem(withTitle: selectedTitle)
        } else {
            self.destinationsSelector.selectItem(at: 0)
        }
        self.selectedDir = userDefaults.string(forKey: "destinationSelectedPath_\(self.selectionSaveKey!)")
        
    }
    
    private func setup() {
        if let storedValuesJsonString = userDefaults.string(forKey: "downloadDestinations") {
            self.values = self.JsonStringToValues(jsonString: storedValuesJsonString)
        }
        
        self.destinationsSelector.removeAllItems()
        for (title, _) in self.values {
            if "SEPARATOR" == title {
                self.destinationsSelector.menu?.addItem(NSMenuItem.separator())
            } else {
                self.destinationsSelector.addItem(withTitle: title)
            }
        }
    }
    
    
    private func valuesToJsonString(values: [(String, String?)]) -> String {
        var arr: [[String?]] = []
        for (title, path) in values {
            arr.append([title, path])
        }
        return JSON(arr).rawString()!
    }
    
    
    private func JsonStringToValues(jsonString: String) -> [(String, String?)] {
        var arr: [(String, String?)] = []
        let json = JSON.init(parseJSON: jsonString)
        for (val) in json.arrayValue {
            arr.append((val[0].stringValue, val[1].stringValue))
        }
        return arr
    }
    
    
    private func addDirToListAndSelect(path: String) {
        self.values.removeAll(where: {$0.1 == path})

        if self.values.count == 3 {  // only default values
            self.values.insert(("SEPARATOR", nil), at: 1)
            self.destinationsSelector.menu?.insertItem(NSMenuItem.separator(), at: 1)
        }
        
        let dirName = path.split(separator: "/").last!
        let title = "\(dirName) (\(path))"
        self.destinationsSelector.insertItem(withTitle: title, at: 2)
        self.values.insert((title, path), at: 2)
        self.destinationsSelector.selectItem(at: 2)
        if self.selectionSaveKey != nil {
            userDefaults.set(title, forKey: "destinationSelectedTitle_\(self.selectionSaveKey!)")
            userDefaults.set(path, forKey: "destinationSelectedPath_\(self.selectionSaveKey!)")
        }
        self.selectedDir = path
        
        // store all directories
        let dirsJsonString = self.valuesToJsonString(values: self.values)
        userDefaults.set(dirsJsonString, forKey: "downloadDestinations")
    }
    
    
    @IBAction func destinationSelectorSelected(_ sender: Any) {
        if self.destinationsSelector.selectedItem?.title == "Other..." {
            self.destinationsSelector.selectItem(at: 0)
            let selectorVC = mainViewController!.storyboard?.instantiateController(withIdentifier: "dirSelectorVC") as! ChooseDestViewController
            selectorVC.completion = { selectedPath in
                self.addDirToListAndSelect(path: selectedPath!)
            }
            currentViewController!.presentAsSheet(selectorVC)
        } else {
            let (selectedTitle, selectedPath) = self.values[self.destinationsSelector.indexOfSelectedItem]
            self.selectedDir = selectedPath
            if self.selectionSaveKey != nil {
                userDefaults.set(selectedTitle, forKey: "destinationSelectedTitle_\(self.selectionSaveKey!)")
                userDefaults.set(selectedPath, forKey: "destinationSelectedPath_\(self.selectionSaveKey!)")
            }
        }
    }

}
