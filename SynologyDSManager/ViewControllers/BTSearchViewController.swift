//
//  BTSearchViewController.swift
//  SynologyDSManager
//
//  Created by Антон on 19.04.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Foundation
import Cocoa

import SwiftyJSON


class BTSearchController: NSViewController {
    @IBOutlet weak var queryTextField: NSTextField!
    @IBOutlet weak var resultsTableview: NSTableView!
    @IBOutlet weak var noResultsLabel: NSTextField!
    @IBOutlet weak var searchSpinner: NSProgressIndicator!
    @IBOutlet weak var searchButton: NSButton!
    @IBOutlet weak var instructionsButton: NSButton!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var searchLabel: NSTextField!
    @IBOutlet weak var destinationView: DestinationView!
    
    
    var searchResultsJSON: JSON? = nil
    
    
    @IBAction func instructionsButtonClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "http://www.synoboost.com/installation/")!)
    }
    
    
    @IBAction func searchButtonClicked(_ sender: Any) {
        self.searchResultsJSON = JSON([])
        self.resultsTableview.reloadData()
        let query = queryTextField.stringValue
        self.queryTextField.isEditable = false
        self.noResultsLabel.isHidden = true
        self.searchSpinner.isHidden = false
        self.searchLabel.isHidden = false
        self.searchButton.isEnabled = false
        self.searchSpinner.startAnimation(self)
        synologyClient?.searchDownloads(query: query, completion: { results in
            self.searchSpinner.isHidden = true
            self.searchLabel.isHidden = true
            self.searchButton.isEnabled = true
            self.queryTextField.isEditable = true
            self.searchResultsJSON = results
            if results.count == 0 {
                self.noResultsLabel.isHidden = false
            }
            self.resultsTableview.reloadData()
        })
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        for elem in searchResultsJSON! {
            let (_, json) = elem
            if json["selected"].boolValue {
                synologyClient?.startDownload(URL: json["dlurl"].stringValue, destination: self.destinationView.selectedDir)
            }
        }
        self.view.window?.close()
    }
    
    func selectedResultsChanged() {
        var selectedCount = 0
        var selectedSize: Double = 0
        
        for elem in searchResultsJSON! {
            let (_, json) = elem
            if json["selected"].boolValue {
                selectedCount += 1
                selectedSize += json["size"].doubleValue
            }
        }
        
        if selectedCount != 0 {
            self.downloadButton.isEnabled = true
            self.downloadButton.state = .on
            self.downloadButton.highlight(true)
            self.downloadButton.title = "Download \(selectedCount) torrents (\(prettifyBytesCount(bytesCount: selectedSize)))"
        } else {
            self.downloadButton.isEnabled = false
            self.downloadButton.title = "Select at least one search result"
        }
    }
    
    func setResultsSortDescriptors() {
        self.resultsTableview.tableColumns[1].sortDescriptorPrototype = NSSortDescriptor(key: "title", ascending: true)
        self.resultsTableview.tableColumns[2].sortDescriptorPrototype = NSSortDescriptor(key: "size", ascending: true)
        self.resultsTableview.tableColumns[3].sortDescriptorPrototype = NSSortDescriptor(key: "date", ascending: true)
        self.resultsTableview.tableColumns[4].sortDescriptorPrototype = NSSortDescriptor(key: "seeds", ascending: true)
        self.resultsTableview.tableColumns[5].sortDescriptorPrototype = NSSortDescriptor(key: "peers", ascending: true)
        self.resultsTableview.tableColumns[6].sortDescriptorPrototype = NSSortDescriptor(key: "source", ascending: true)
    }
    
    override func viewDidLoad() {
        self.resultsTableview.dataSource = self
        self.setResultsSortDescriptors()
        
        let instructionsButtonAttributedTitle = NSAttributedString(string: "here", attributes: [
            NSAttributedString.Key.foregroundColor: NSColor.linkColor,
            NSAttributedString.Key.cursor: NSCursor.pointingHand
        ])
        self.instructionsButton.attributedTitle = instructionsButtonAttributedTitle
        
        self.destinationView.setSelectionSynchronizeKey(key: "main")
    }
}

extension BTSearchController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        searchResultsJSON?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        let sortDescriptor = self.resultsTableview.sortDescriptors.first!
        let sortedSearchResults = self.searchResultsJSON?.sorted(by: {(left: (String, JSON), right: (String, JSON)) in
            switch sortDescriptor.key! {
            case "title", "date", "source":
                let lhsVal = left.1[sortDescriptor.key!].stringValue
                let rhsVal = right.1[sortDescriptor.key!].stringValue
                return sortDescriptor.ascending ? lhsVal < rhsVal : lhsVal > rhsVal
            case "size", "seeds", "peers":
                let lhsVal = left.1[sortDescriptor.key!].doubleValue
                let rhsVal = right.1[sortDescriptor.key!].doubleValue
                return sortDescriptor.ascending ? lhsVal < rhsVal : lhsVal > rhsVal
            default:
                return false
            }
        })
        self.searchResultsJSON = JSON(sortedSearchResults?.map({return $0.1}))
        self.resultsTableview.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if self.resultsTableview.tableColumns.lastIndex(of: tableColumn!) == 0 {
            searchResultsJSON![row]["selected"].boolValue = object as! Bool
            
            self.selectedResultsChanged()
        }
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let elem = searchResultsJSON![row]
        switch tableColumn?.title {
        case "Name":
            return elem["title"].stringValue
        case "Size":
            return prettifyBytesCount(bytesCount: elem["size"].doubleValue)
        case "Date":
            return elem["date"].stringValue
        case "Seeds":
            return elem["seeds"].stringValue
        case "Peers":
            return elem["peers"].stringValue
        case "Source":
            return elem["provider"].stringValue
        default:
            return elem["selected"].boolValue
        }
    }
}

