//
//  ViewController.swift
//  SynologyDSManager
//
//  Created by Антон on 17.01.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Cocoa
import SafariServices.SFSafariApplication

import SwiftyJSON


class ModalView: NSView {
    override func mouseDown(with event: NSEvent) {}
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}


class SettingsViewController: NSViewController {

    @IBOutlet weak var hostTextField: NSTextField!
    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    @IBOutlet weak var passwordSecureTextField: NSSecureTextField!
    @IBOutlet weak var otpSecureTextField: NSSecureTextField!
    @IBOutlet weak var otpCheckbox: NSButton!
    @IBOutlet weak var contactButton: NSButton!
    @IBOutlet weak var extensionDestinationView: DestinationView!
    
    @IBOutlet weak var hideDockIconCheckbox: NSButton!
    @IBOutlet weak var hideFromStatusBarCheckbox: NSButton!
    @IBOutlet weak var clearFinishedTasksCheckbox: NSButton!
    
    
    let userDefaults = UserDefaults()
    var loaderView: NSView?
    
    private func showLoader() {
        print("loader...")
        self.loaderView = ModalView(frame: self.view.frame)
        self.loaderView!.wantsLayer = true
        self.loaderView!.layer!.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        let pi = NSProgressIndicator()
        pi.style = NSProgressIndicator.Style.spinning
        pi.startAnimation(self)
        pi.controlSize = NSControl.ControlSize.regular
        pi.setFrameSize(NSSize(width: 30, height: 30))
        pi.setFrameOrigin(NSPoint(x: (self.loaderView?.frame.size.width)!/2-15, y: (self.loaderView?.frame.size.height)!/2-15))
        self.loaderView?.addSubview(pi)
        self.view.addSubview(self.loaderView!, positioned: NSWindow.OrderingMode.above, relativeTo: self.view)
        self.view.window?.makeFirstResponder(self.loaderView)
    }
    
    private func hideLoader() {
        self.loaderView?.removeFromSuperview()
        self.loaderView = nil
    }
    
    @IBAction func otpCheckboxClicked(_ sender: Any) {
        otpSecureTextField.stringValue = ""
        otpSecureTextField.isEnabled = (otpCheckbox.state == .on)
    }
    
    @IBAction func hideDockIconCheckboxClicked(_ sender: Any) {
        userDefaults.set(.on == hideDockIconCheckbox.state, forKey: "hideDockIcon")
        
        if .on == hideDockIconCheckbox.state {
            self.view.window?.canHide = false
            NSApp.setActivationPolicy(.accessory)
            NSApp.activate(ignoringOtherApps:true)
        } else {
            NSApp.setActivationPolicy(.regular)
            mainViewController!.view.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: false)
        }
    }
    
    @IBAction func hideFromStatusBarCheckboxClicked(_ sender: Any) {
        userDefaults.set(.on == hideFromStatusBarCheckbox.state, forKey: "hideFromStatusBar")
    }
    
    
    @IBAction func clearFinishedTasksCheckboxClicked(_ sender: Any) {
        userDefaults.set(.on == clearFinishedTasksCheckbox.state, forKey: "clearFinishedTasks")
    }
    
    
    
    
    @IBAction func contactButtonClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "mailto:support@swiftapps.skavans.ru?subject=Synology%20DS%20Manager")!)
    }
    
    @IBAction func testConnectionButtonClicked(_ sender: Any) {
        self.showLoader()
        
        let testClient = SynologyClient(host: hostTextField.stringValue,
                                        port: portTextField.stringValue,
                                        username: usernameTextField.stringValue,
                                        password: passwordSecureTextField.stringValue,
                                        otpCode: otpSecureTextField.stringValue)
        testClient.authenticate(completion: {success, error in
            let alert: NSAlert
            alert = NSAlert()
            if success {
                storeSettings(settings: testClient.settings)
                if !workStarted {
                    mainMethod!(testClient.settings)
                } else {
                    synologyClient!.settings = testClient.settings
                }
                alert.messageText = "Success"
                alert.informativeText = "Connection attempt is successful. Your connection settings is saved now so you don't need to enter the credentials manually anymore."
            } else {
                alert.alertStyle = NSAlert.Style.critical
                alert.messageText = "Error"
                alert.informativeText = error!.localizedDescription
            }
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: {resp in
                self.hideLoader()
                if success {
                    self.view.window?.close()
                }
            })
        })
        
    }
    
    override func viewDidDisappear() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        mainViewController!.view.window!.makeKey()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.extensionDestinationView.setSelectionSynchronizeKey(key: "extension")
    }
    
    override func viewWillAppear() {
        portTextField.stringValue = "5001"
        if let settings = readSettings() {
            hostTextField.stringValue = settings.host
            portTextField.stringValue = settings.port
            usernameTextField.stringValue = settings.username
            passwordSecureTextField.stringValue = settings.password
        }
        
        hideDockIconCheckbox.state = userDefaults.value(forKey: "hideDockIcon") as? Bool ?? true ? .on : .off
        hideFromStatusBarCheckbox.state = userDefaults.value(forKey: "hideFromStatusBar") as? Bool ?? false ? .on : .off
        clearFinishedTasksCheckbox.state = userDefaults.value(forKey: "clearFinishedTasks") as? Bool ?? false ? .on : .off
        
        self.view.window?.styleMask.remove(.fullScreen)
        self.view.window?.styleMask.remove(.miniaturizable)
        self.view.window?.styleMask.remove(.resizable)
    }
    
    @IBAction func openSafariExtensionPreferences(_ sender: AnyObject?) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.skavans.synologyDSManager.extension") { error in
            if let _ = error {
                // Insert code to inform the user that something went wrong.

            }
        }
    }

}
