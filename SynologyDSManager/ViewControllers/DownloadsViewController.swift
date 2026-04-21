//
//  DownloadsViewController.swift
//  SynologyDSManager
//
//  Created by Антон on 14.03.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Cocoa
import Foundation

import SwiftyJSON


class DownloadsViewController: NSViewController, NSWindowDelegate {
    
    var tasks: JSON?
    
    var finishedTasks: Set<String> = []
    
    var statusBarItem: NSStatusItem? = nil
            
    @IBOutlet weak var downloadsTableView: NSTableView!
    @IBOutlet weak var bandwidthLabel: NSTextField!
    @IBOutlet weak var downloadsPlaceholderLabel: NSTextField!
        
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
        
    @IBAction func settingsMenuItemClicked(_ sender: AnyObject?) {
        self.showStoryboardWindowCenteredToMainWindow(storyboardWindowControllerIdentifier: "SettingsWC")
    }
    
    @IBAction func addDownloadMenuItemClicked(_ sender: AnyObject?) {
        self.showStoryboardWindowCenteredToMainWindow(storyboardWindowControllerIdentifier: "addDownloadWC")
    }
    
    @IBAction func searchToolbarItemClicked(_ sender: AnyObject?) {
        self.showStoryboardWindowCenteredToMainWindow(storyboardWindowControllerIdentifier: "SearchBTWC")
    }
    
    @IBAction func cleanToolbarItemClicked(_ sender: AnyObject?) {
        for task in self.tasks ?? [] {
            if "finished" == task.1["status"].stringValue {
                synologyClient?.deleteDownload(taskID: task.1["id"].stringValue)
            }
        }
    }
    
    @IBAction func resumeAllToolbarItemClicked(_ sender: AnyObject?) {
        for task in self.tasks ?? [] {
            synologyClient?.resumeDownload(taskID: task.1["id"].stringValue)
        }
    }
    
    @IBAction func pauseAllToolbarItemClicked(_ sender: AnyObject?) {
        for task in self.tasks ?? [] {
            synologyClient?.pauseDownload(taskID: task.1["id"].stringValue)
        }
    }
    
    @IBAction func aboutMenuItemClicked(_ sender: AnyObject?) {
        self.showStoryboardWindowCenteredToMainWindow(storyboardWindowControllerIdentifier: "AboutWC")
    }
    
    @IBAction func clearStateMenuItemClicked(_ sender: AnyObject?) {
        userDefaults.removeObject(forKey: "syno_conn_settings")
    }
    
    
    public func showStoryboardWindowCenteredToMainWindow(storyboardWindowControllerIdentifier: String) {
        let windowController = self.storyboard?.instantiateController(withIdentifier: storyboardWindowControllerIdentifier) as! NSWindowController
        let window = windowController.window!
        let mainWindow = self.view.window!
        let frame = mainWindow.frame
        let newLeft = frame.midX - window.frame.width / 2
        let newTop = frame.midY + window.frame.height / 2
        window.setFrameTopLeftPoint(NSPoint(x: newLeft, y: newTop))
        windowController.showWindow(self)
        currentViewController = windowController.contentViewController
    }
    
    
    private func notificateTaskFinished(title: String) {
        let notification = NSUserNotification()
        notification.title = "Task finished"
        notification.informativeText = title
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    
    private func refreshDownloads() {
        synologyClient?.getDownloads(completion: {success, tasks, error in
            if success {
                
                let isFirstDataReceived = self.tasks == nil
                
                for t in tasks ?? [] {
                    if "finished" == t.1["status"].stringValue {
                        let title = t.1["title"].stringValue
                        if !self.finishedTasks.contains(title) {
                            if !isFirstDataReceived {
                                self.notificateTaskFinished(title: title)
                            }
                            self.finishedTasks.insert(title)
                        }
                        
                        if userDefaults.bool(forKey: "clearFinishedTasks") {
                            synologyClient?.deleteDownload(taskID: t.1["id"].stringValue)
                        }
                        
                    }
                }
                
                self.tasks = tasks
                
                self.downloadsPlaceholderLabel.isHidden = tasks?.count != 0
                
                let bandwidth = tasks?.reduce(0, {(acc, elem) in
                    return acc + elem.1["additional"]["transfer"]["speed_download"].doubleValue
                }) ?? 0
                self.bandwidthLabel.stringValue = "Bandwidth: \(prettifySpeed(speed: bandwidth))"
                self.statusBarItem!.button?.title = userDefaults.bool(forKey: "hideFromStatusBar") ? "↓DS" : "↓DS: \(prettifySpeed(speed: bandwidth))"
                
                self.downloadsTableView.reloadData()
            }
        })
    }
    
    
    private func doWork(settings: SynologyClient.ConnectionSettings) {
        synologyClient = SynologyClient(settings: settings)
                
        start_webserver()
        
        self.refreshDownloads()
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: {timer in
            self.refreshDownloads()
        })
    }
    
    public func downloadByURLFromExtension(URL: String) {
        registerEvent(type: "firstExtensionUse", unique: true)
        DispatchQueue.main.async {
            let notification = NSUserNotification()
            notification.title = "Download started"
            notification.subtitle = "URL content is downloading at Synology DS"
            NSUserNotificationCenter.default.deliver(notification)
            let extensionDestination = userDefaults.string(forKey: "destinationSelectedPath_extension")
            synologyClient?.startDownload(URL: URL, destination: extensionDestination)
        }
    }
    
    @objc func showWindow() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    func initStatusBar() {
        
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem!.button?.title = userDefaults.bool(forKey: "hideFromStatusBar") ? "↓DS" : "↓DS: 0.0 B/s"
        
        let statusBarMenu = NSMenu(title: "Synology DS Manager Status Bar Menu")
        statusBarItem?.menu = statusBarMenu
        
        // Status Bar Menu elements
        
        statusBarMenu.addItem(NSMenuItem.separator())
        
        let pauseAllItem = NSMenuItem(title: "Pause all", action: #selector(pauseAllToolbarItemClicked), keyEquivalent: "")
        pauseAllItem.target = self
        statusBarMenu.addItem(pauseAllItem)
        
        let startAllItem = NSMenuItem(title: "Start all", action: #selector(resumeAllToolbarItemClicked), keyEquivalent: "")
        startAllItem.target = self
        statusBarMenu.addItem(startAllItem)
        
        let cleanItem = NSMenuItem(title: "Clear finished", action: #selector(cleanToolbarItemClicked), keyEquivalent: "")
        cleanItem.target = self
        statusBarMenu.addItem(cleanItem)
        
        statusBarMenu.addItem(NSMenuItem.separator())
        
        let showWindowItem = NSMenuItem(title: "Show window", action: #selector(showWindow), keyEquivalent: "")
        showWindowItem.target = self
        statusBarMenu.addItem(showWindowItem)
        
        statusBarMenu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(title: "About", action: #selector(aboutMenuItemClicked), keyEquivalent: "")
        aboutItem.target = self
        statusBarMenu.addItem(aboutItem)
        
        statusBarMenu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        statusBarMenu.addItem(quitItem)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        registerEvent(type: "firstOpen", unique: true)
        
        mainViewController = self
        mainMethod = self.doWork
        
        downloadsTableView.delegate = self
        downloadsTableView.dataSource = self
        
        self.initStatusBar()
        
        if !(userDefaults.value(forKey: "hideDockIcon") as? Bool ?? true) {
            NSApp.setActivationPolicy(.regular)
        }
    }
    
    override func viewDidAppear() {
        self.view.window!.delegate = self
        DispatchQueue.main.async {
            if let connSettings = readSettings() {
                self.doWork(settings: connSettings)
            } else {
                self.settingsMenuItemClicked(self)
            }
        }
    }

}

extension DownloadsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.tasks?.count ?? 0
    }
}


extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


extension DownloadsViewController: NSTableViewDelegate {
    
    @objc func startPauseButtonClicked(button: NSButton) {
        let row = self.downloadsTableView.row(for: button.superview!)
        let task = self.tasks![row]
        let currentTaskState = task["status"].stringValue
        switch currentTaskState {
        case "paused":
            synologyClient?.resumeDownload(taskID: task["id"].stringValue)
            break
        case "downloading":
            synologyClient?.pauseDownload(taskID: task["id"].stringValue)
            break
        default:
            break
        }
    }
    
    @objc func deleteButtonClicked(button: NSButton) {
        let row = self.downloadsTableView.row(for: button.superview!)
        let task = self.tasks![row]
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.warning
        alert.messageText = "Confirm deletion"
        alert.informativeText = "Are you sure you want to delete download \"\(task["title"].stringValue)\"?"
        alert.addButton(withTitle: "No")
        alert.addButton(withTitle: "Yes")
        let isConfirmed = alert.runModal().rawValue == 1001
        if isConfirmed {
            synologyClient?.deleteDownload(taskID: task["id"].stringValue)
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = DownloadsCellView()
        let task = (self.tasks?[row])!
        view.downloadNameLabel.stringValue = task["title"].stringValue
        let progress: Double
        if task["size"].doubleValue != 0 {
            progress = (task["additional"]["transfer"]["size_downloaded"].doubleValue / task["size"].doubleValue) * 100
        } else {
            progress = 0
        }
        view.progressIndicator.doubleValue = progress
        let progressString = "\(prettifyBytesCount(bytesCount: task["additional"]["transfer"]["size_downloaded"].doubleValue)) of \(prettifyBytesCount(bytesCount: task["size"].doubleValue)) (\(Int(progress ))%)"
        view.progressLabel.stringValue = progressString
        view.statusLabel.stringValue = "\(task["status"].stringValue)\n\(prettifySpeed(speed: task["additional"]["transfer"]["speed_download"].doubleValue))"
        switch task["status"].stringValue {
        case "finished":
            view.startPauseButton.image = NSImage.init(named: "NSStatusNoneTemplate")
            break
        case "paused":
            view.startPauseButton.image = NSImage.init(named: "NSTouchBarPlayTemplate")
            break
        case "downloading":
            view.startPauseButton.image = NSImage.init(named: "NSTouchBarPauseTemplate")
            break
        default:
            break
        }
        
        view.startPauseButton.action = #selector(DownloadsViewController.startPauseButtonClicked)
        view.deleteButton.action = #selector(DownloadsViewController.deleteButtonClicked)
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 47
    }
}
