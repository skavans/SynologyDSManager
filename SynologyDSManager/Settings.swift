//
//  Settings.swift
//  SynologyDSManager
//
//  Created by Антон on 14.03.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Foundation

import KeychainAccess
import SwiftyJSON


let userDefaults = UserDefaults()
let keychain = Keychain(service: "com.skavans.synologyDSManager")


func storeSettings(settings: SynologyClient.ConnectionSettings) {
    let settingsDict = [
        "host": settings.host,
        "port": settings.port,
        "username": settings.username,
        "password": settings.password,
        "otp": settings.otp,
        "sid": settings.sid
    ]
    keychain["syno_conn_settings"] = JSON(settingsDict).rawString()
}


func readSettings() -> SynologyClient.ConnectionSettings? {
    
    // if the settings are found in UserDefaults, move them into the Keychain
    if let settingsDict = userDefaults.dictionary(forKey: "syno_conn_settings") {
        keychain["syno_conn_settings"] = JSON(settingsDict).rawString()
        userDefaults.set(nil, forKey: "syno_conn_settings")
    }
    
    if let settingsJSON = keychain["syno_conn_settings"] {
        let settingsDict = (JSON(parseJSON: settingsJSON).dictionary)!
        let settings = SynologyClient.ConnectionSettings(host: settingsDict["host"]?.stringValue ?? "",
                                                         port: settingsDict["port"]?.stringValue ?? "",
                                                         username: settingsDict["username"]?.stringValue ?? "",
                                                         password: settingsDict["password"]?.stringValue ?? "",
                                                         otp: settingsDict["otp"]?.stringValue ?? "",
                                                         sid: settingsDict["sid"]?.stringValue ?? "")
        return settings
    } else {
        return nil
    }
}
