//
//  SafariExtensionViewController.swift
//  SynologyDSManager Extension
//
//  Created by Антон on 17.01.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:660, height:180)
        return shared
    }()

}
