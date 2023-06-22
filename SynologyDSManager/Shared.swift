//
//  Shared.swift
//  SynologyDSManager
//
//  Created by Антон on 16.03.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Foundation
import Cocoa

import Alamofire


var synologyClient: SynologyClient?

var workStarted = false
var mainMethod: ((SynologyClient.ConnectionSettings) -> Void)? = nil

var mainViewController: DownloadsViewController? = nil

var currentViewController: NSViewController? = nil


func registerEvent(type: String, unique: Bool) {
}


func prettifyBytesCount(bytesCount: Double) -> String {
    var factor = 1.0
    var unit = "B"
    if bytesCount > pow(1024, 4) {
        factor = pow(1024, 4)
        unit = "TB"
    } else if bytesCount > pow(1024, 3) {
        factor = pow(1024, 3)
        unit = "GB"
    } else if bytesCount > pow(1024, 2) {
        factor = pow(1024, 2)
        unit = "MB"
    } else if bytesCount > 1024 {
        factor = 1024
        unit = "KB"
    }
    
    return "\((bytesCount / factor).round(to: 2)) \(unit)"
}


func prettifySpeed(speed: Double) -> String {
    var factor = 1.0
    var unit = "B/s"
    if speed > pow(1024, 4) {
        factor = pow(1024, 4)
        unit = "TB/s"
    } else if speed > pow(1024, 3) {
        factor = pow(1024, 3)
        unit = "GB/s"
    } else if speed > pow(1024, 2) {
        factor = pow(1024, 2)
        unit = "MB/s"
    } else if speed > 1024 {
        factor = 1024
        unit = "KB/s"
    }
    
    return "\((speed / factor).round(to: 2)) \(unit)"
}
