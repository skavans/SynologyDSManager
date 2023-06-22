//
//  ChooseDestinationViewController.swift
//  SynologyDSManager
//
//  Created by Антон on 22.04.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Foundation
import Cocoa


class ChooseDestViewController: NSViewController {

    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var dirsOutlineView: NSOutlineView!
    
    var remoteDirs: [RemoteDir] = []
    
    public var completion: ((_ selectedPath: String?) -> ())? = nil
        
    @IBAction func cancelButtonClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func okButtonClicked(_ sender: Any) {
        let selectedRow = self.dirsOutlineView.selectedRow
        let selectedItem = self.dirsOutlineView.item(atRow: selectedRow)
        let selectedPath = (selectedItem as! RemoteDir).absolutePath
        self.dismiss(self)
        completion!(selectedPath)
    }
    
    override func viewDidLoad() {
        self.dirsOutlineView.dataSource = self
        self.dirsOutlineView.delegate = self
        
        synologyClient?.listDirs(root: "/", completion: {results in
            self.remoteDirs = results
            self.dirsOutlineView.reloadData()
        })
    }

}


extension ChooseDestViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if nil == item {  // root
            return self.remoteDirs.count
        } else {
            return (item as! RemoteDir).children.count
        }
        
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if nil == item {  // root
            return remoteDirs[index]
        } else {
            return (item as! RemoteDir).children[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        let remoteDir = item as! RemoteDir
        if 0 == remoteDir.children.count {
            
            synologyClient?.listDirs(root: remoteDir.absolutePath, completion: {results in
                remoteDir.children = results
                self.dirsOutlineView.expandItem(remoteDir)
            })
            return false
        } else {
            return true
        }
    }
}


extension ChooseDestViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let remoteDir = item as? RemoteDir {
            let view = dirsOutlineView.makeView(withIdentifier: .init("DataCell"), owner: self) as! NSTableCellView
            view.textField?.stringValue = remoteDir.name
            return view
        } else {
            return nil
        }
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        self.okButton.isEnabled = true
    }
    
}
