//
//  SynologyClient.swift
//  SynologyDSManager
//
//  Created by Антон on 20.01.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Foundation

import Alamofire
import SwiftyJSON


class RemoteDir {
    let name: String
    var children: [RemoteDir] = []
    let absolutePath: String
    
    init(name: String, children: [RemoteDir]?, absolutePath: String) {
        self.name = name
        self.children = children ?? []
        self.absolutePath = absolutePath
    }
}


class AuthError: Error, LocalizedError {
    
    let description: String
    
    init(description: String) {
        self.description = description
    }
    
    public var errorDescription: String? {
        return NSLocalizedString(self.description, comment: "error description")
    }
}


class SynologyClient {
    
    struct ConnectionSettings {
        var host: String
        var port: String
        var username: String
        var password: String
        var otp: String
        var sid: String?
    }
    
    var session: Session
    var settings: ConnectionSettings
    
    
    init(host: String, port: String, username: String, password: String, otpCode: String) {
        settings = ConnectionSettings(host: host, port: port, username: username, password: password, otp: otpCode)
        let manager = ServerTrustManager(evaluators: [settings.host: DisabledEvaluator()])
        session = Session(serverTrustManager: manager)
    }
    
    init(settings: ConnectionSettings) {
        self.settings = settings
        let manager = ServerTrustManager(evaluators: [settings.host: DisabledEvaluator()])
        session = Session(serverTrustManager: manager)
    }
    
    func authenticate(completion: @escaping (_ success: Bool, _ error: Error?) -> ()) {
        session.request("https://\(settings.host):\(settings.port)/webapi/auth.cgi", parameters: [
            "api": "SYNO.API.Auth",
            "version": "3",
            "method": "login",
            "account": settings.username,
            "passwd": settings.password,
            "otp_code": settings.otp,
            "session": "DownloadStation",
            "format": "sid"], encoding: URLEncoding.default).validate().responseJSON { response in
    
            switch response.result {
                case .success(let value):
                    let data = JSON(value)
                    let success = data["success"]
                    if (success.boolValue) {
                        self.settings.sid = data["data"]["sid"].stringValue
                        completion(true, nil)
                    }
                    else {
                        var errorMessage = "Unknow error. Code \(data["error"]["code"].intValue)"
                        switch data["error"]["code"].intValue {
                        case 400:
                            errorMessage = "No such account or incorrect password"
                        case 401:
                            errorMessage = "Account disabled"
                        case 402:
                            errorMessage = "Permission denied or the 2-step verification code required"
                        case 403:
                            errorMessage = "2-step verification code required"
                        case 404:
                            errorMessage = "Failed to authenticate 2-step verification code"
                        default:
                            break
                        }
                        completion(false, AuthError(description: errorMessage))
                    }
                case .failure(let error):
                    completion(false, AuthError(description: error.localizedDescription))
            }
            
        }
    }
    
    func getDownloads(completion: @escaping (_ success: Bool, _ tasks: JSON?, _ error: Error?) -> ()) {
        session.request("https://\(settings.host):\(settings.port)/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=list&additional=detail,transfer&_sid=\(settings.sid!)").validate().responseJSON{ response in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                let success = data["success"]
                if (success.boolValue) {
                    registerEvent(type: "get_downloads_ok", unique: true)
                    completion(true, data["data"]["tasks"], nil)
                } else {
                    print("get downloads failed")
                    completion(false, nil, AuthError(description: "unknown"))
                }
            case .failure(let error):
                print(error)
                print(error.errorDescription)
                completion(false, nil, AuthError(description: "unknown"))
            }
        }
    }
    
    func pauseDownload(taskID: String) {
        session.request("https://\(settings.host):\(settings.port)/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=pause&id=\(taskID)&_sid=\(settings.sid!)").validate().responseJSON{ response in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                let success = data[0]["error"].intValue == 0
                if success {
                } else {
                    print("Pause failed")
                }
            case .failure(let error):
                print(error)
                print(error.errorDescription)
            }
        }
    }
    
    func resumeDownload(taskID: String) {
        session.request("https://\(settings.host):\(settings.port)/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=resume&id=\(taskID)&_sid=\(settings.sid!)").validate().responseJSON{ response in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                let success = data[0]["error"].intValue == 0
                if success {
                } else {
                    print("Resume failed")
                }
            case .failure(let error):
                print(error)
                print(error.errorDescription)
            }
        }
    }
    
    func deleteDownload(taskID: String) {
        session.request("https://\(settings.host):\(settings.port)/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=delete&id=\(taskID)&_sid=\(settings.sid!)").validate().responseJSON{ response in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                let success = data[0]["error"].intValue == 0
                if success {
                } else {
                    print("Delete failed")
                }
            case .failure(let error):
                print(error)
                print(error.errorDescription)
            }
        }
    }
    
    func startDownload(torrentFilePath: String, destination: String?) {
        session.upload(multipartFormData: {multipart in
            multipart.append("SYNO.DownloadStation2.Task".data(using: .utf8)!, withName: "api")
            multipart.append("2".data(using: .utf8)!, withName: "version")
            multipart.append("create".data(using: .utf8)!, withName: "method")
            multipart.append("\"file\"".data(using: .utf8)!, withName: "type")
            multipart.append("[\"torrent\"]".data(using: .utf8)!, withName: "file")
            multipart.append("false".data(using: .utf8)!, withName: "create_list")
            var dest = destination
            if dest == nil {
                dest = ""
            }
            multipart.append(("\"" + dest!.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "\"").data(using: .utf8)!, withName: "destination")
            let fileData = try! Data(contentsOf: URL(fileURLWithPath: torrentFilePath))
            multipart.append(fileData, withName: "torrent", fileName: "task.torrent", mimeType: "application/x-bittorent")
        }, to: "https://\(settings.host):\(settings.port)/webapi/entry.cgi?_sid=\(self.settings.sid!)").validate().responseJSON{ response in
            registerEvent(type: "task_added_by_torrent", unique: true)
            print(response)
        }
    }
    
    func startDownload(URL: String, destination: String?) {
        var params = [
            "api": "SYNO.DownloadStation.Task",
            "version": "1",
            "method": "create",
            "uri": URL,
            "_sid": self.settings.sid!
        ]
        if destination != nil {
            params["destination"] = destination!.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        session.request("https://\(settings.host):\(settings.port)/webapi/DownloadStation/task.cgi", method: .post, parameters: params).validate().responseJSON{response in
            registerEvent(type: "task_added_by_url", unique: true)
            print(response)
        }

    }
    
    func searchDownloads(query: String, completion: @escaping (_ results: JSON) -> ()) {
        session.request("https://\(settings.host):\(settings.port)/webapi/entry.cgi", method: .post, parameters: [
            "api": "SYNO.DownloadStation2.BTSearch",
            "version": "1",
            "method": "start",
            "action": "search",
            "keyword": "\"\(query)\"",
            "_sid": self.settings.sid!
        ]).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                let searchId = data["data"]["id"].stringValue
                
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {timer in
                    self.session.request("https://\(self.settings.host):\(self.settings.port)/webapi/entry.cgi", method: .post, parameters: [
                        "api": "SYNO.DownloadStation2.BTSearch",
                        "version": "1",
                        "method": "list",
                        "sort_by": "seeds",
                        "order": "DESC",
                        "offset": 0,
                        "limit": 50,
                        "id": "\"\(searchId)\"",
                        "_sid": self.settings.sid!
                    ]).validate().responseJSON{ response in
                        switch response.result {
                        case .success(let value):
                            let data = JSON(value)
                            if !data["data"]["is_running"].boolValue {
                                timer.invalidate()
                                completion(data["data"]["results"])
                            }
                        case .failure(let error):
                            print("error2")
                        }
                        
                    }
                })
                
            case .failure(let error):
                print("error")
            }
        }
    }
    
    func listDirs(root: String, completion: @escaping (_ children: [RemoteDir]) -> ()) {
        session.request("https://\(settings.host):\(settings.port)/webapi/entry.cgi", method: .post, parameters: [
            "api": "SYNO.Core.File",
            "version": "1",
            "method": "list",
            "filetype": "\"dir\"",
            "superuser": "false",
            "needrw": "true",
            "status_filter": "\"valid\"",
            "folder_path": "\"\(root)\"",
            "_sid": self.settings.sid!
        ]).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let data = JSON(value)
                if data["data"]["files"].arrayValue.count > 0 {
                    let children = data["data"]["files"].arrayValue.map({
                        return RemoteDir(name: $0["name"].stringValue, children: [], absolutePath: $0["path"].stringValue)
                    })
                    completion(children)
                } else {
                    let children = data["data"].arrayValue.map({
                        return RemoteDir(name: $0["text"].stringValue, children: [], absolutePath: $0["spath"].stringValue)
                    })
                    completion(children)
                }
            case .failure(let error):
                break
            }
        }
    }
    
}
