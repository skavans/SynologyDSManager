//
//  Webserver.swift
//  SynologyDSManager
//
//  Created by  skavans on 13.08.2020.
//  Copyright © 2020 skavans. All rights reserved.
//

import Foundation

import Swifter


private func handle_new_download_task(request: HttpRequest) -> HttpResponse {
    
    struct message: Codable {
        let url: String
    }
    
    let request_body = String(bytes: request.body, encoding: .utf8)!
    let request_data = request_body.data(using: .utf8)!
    let decoder = JSONDecoder()
    let data = try! decoder.decode(message.self, from: request_data)
    
    mainViewController!.downloadByURLFromExtension(URL: data.url)
    
    return HttpResponse.raw(200, "OK", ["Access-Control-Allow-Origin": "*"], {try! $0.write("OK".data(using: String.Encoding.utf8)!)})
}


func start_webserver() {
    
    let server = HttpServer()
    
    server["/add_download"] = handle_new_download_task

    do {
        try server.start(11863, forceIPv4: true, priority: DispatchQoS.QoSClass.userInteractive)
        print("Server has started ( port = \(try server.port()) ). Try to connect now...")
    } catch {
        print("Server start error: \(error)")
    }
}
