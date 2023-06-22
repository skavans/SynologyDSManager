//
//  SafariExtensionHandler.swift
//  SynologyDSManager Extension
//
//  Created by Антон on 17.01.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import SafariServices

import Alamofire


class SafariExtensionHandler: SFSafariExtensionHandler {
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        page.getPropertiesWithCompletionHandler { properties in
            NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
        }
        
        switch messageName {
        case "downloadURL":
            
            let params = [
                "url": userInfo!["URL"] as! String
            ]
            
            AF.request("http://localhost:11863/add_download", method: .post, parameters: params, encoding: JSONEncoding.default).responseString {resp in
                switch resp.result {
                case .success(let res):
                    print(res)
                case .failure(let _):
                    let url = URL(string: "synologydsmanager://download?downloadURL=\((userInfo!["URL"] as! String).addingPercentEncoding(withAllowedCharacters: .letters) ?? "")")
                    NSWorkspace.shared.open(url!)
                }
            }

            break
        default:
            break
        }
    
    }
    
    override func contextMenuItemSelected(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil) {
        switch command {
        case "downloadURL":
            page.dispatchMessageToScript(withName: "downloadURL", userInfo: nil)
            break
        default:
            break
        }
    }


}
