//
//  RaiCore.swfit.swift
//  Nano
//
//  Created by Zack Shapiro on 12/19/17.
//  Copyright © 2017 Nano. All rights reserved.
//

import Foundation

import Crashlytics
import RealmSwift
import SwiftWebSocket


extension RaiCore {

    private var socketServerURL: URL? {
        guard
            let path = Bundle.main.path(forResource: "Common", ofType: "plist"),
            let root = NSDictionary(contentsOfFile: path) as? [String: String],
            let urlString = root["socketServerURL"]
        else { return nil }

        return URL(string: urlString)
    }

    func createWorkForOpenBlock(withPublicKey publicKey: String, completion: @escaping ((_ work: String?) -> Void)) {
        let socket = WebSocket(url: socketServerURL!)

        socket.event.message = { message in
            guard let str = message as? String, let data = str.asUTF8Data() else {
                Answers.logCustomEvent(withName: "Create Work For Open Block Failed")

                return completion(nil)
            }

            if let work = try? JSONDecoder().decode(WorkGenerate.self, from: data) {
                socket.close()

                completion(work.work)
            }
        }

        socket.open()
        socket.send(endpoint: Endpoint.createWorkForOpenBlock(publicKey: publicKey))
    }

    func createWork(previousHash previous: String, completion: @escaping ((_ work: String?) -> Void)) {
        let socket = WebSocket(url: socketServerURL!)

        socket.event.message = { message in
            guard let str = message as? String, let data = str.asUTF8Data() else {
                Answers.logCustomEvent(withName: "Create Work Failed")

                return completion(nil)
            }

            if let work = try? JSONDecoder().decode(WorkGenerate.self, from: data) {
                socket.close()

                completion(work.work)
            }
        }

        socket.open()
        socket.send(endpoint: Endpoint.createWork(previousHash: previous))
    }

}
