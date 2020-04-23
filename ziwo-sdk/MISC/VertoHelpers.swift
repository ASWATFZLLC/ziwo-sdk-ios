//
//  VertoHelpers.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 23/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import SwiftyJSON
import Defaults
import CommonCrypto

enum VertoEvent: String {
    case ClientReady = "verto.clientReady"
    case Media = "verto.media"
    case Invite = "verto.invite"
    case Display = "verto.display"
    case Bye = "verto.bye"
}

class VertoHelpers {
    
    static var REMOTE_NUMBER = ""
    
    static func toMd5(value: String) -> String {
        let data = Data(value.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    static func convertStringToDictionary(_ message: String) -> [String: AnyObject]? {
        if let data = message.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    static func getLoginRPC(agentNumber: String, ccPassword: String) -> JSON {
        let password = VertoHelpers.toMd5(value: "\(agentNumber + ccPassword)")
        let sessId = UUID().uuidString.lowercased()
        return JSON([
            "jsonrpc": "2.0",
            "method": "login",
            "params": [
                "login": "agent-\(agentNumber)@\(Defaults[.domain])",
                "passwd": "\(password)",
                "sessid": "\(sessId)",
            ],
            "id": 3
        ])
    }
    
    static func createCallRPC(method: String, agent: String, sdp: String, sessId: String, callID: String) -> JSON {
        let tag = UUID().uuidString.lowercased()
        return JSON([
            "jsonrpc": "2.0",
            "method": "verto.\(method)",
            "params": [
                "sdp": sdp,
                "dialogParams": [
                    "useStereo": true,
                    "screenShare": false,
                    "useCamera": false,
                    "useMic": true,
                    "useSpeak": true,
                    "tag": tag,
                    "localTag": nil,
                    "login": agent,
                    "videoParams": [],
                    "destination_number": VertoHelpers.REMOTE_NUMBER,
                    "caller_id_name": "",
                    "caller_id_number": "",
                    "outgoingBandwidth": "default",
                    "incomingBandwidth": "default",
                    "dedEnc": false,
                    "audioParams": [
                        "googAutoGainControl": false,
                        "googNoiseSuppression": false,
                        "googHighpassFilter": false
                    ],
                    "callID": callID,
                    "remote_caller_id_name": "Outbound Call",
                    "remote_caller_id_number": VertoHelpers.REMOTE_NUMBER
                ],
                "sessid": sessId
            ],
            "id": 4
        ])
    }
    
    static func createHoldAction(agent: String, sessId: String, callID: String, isOn: Bool) -> JSON {
        let tag = UUID().uuidString.lowercased()
        return JSON([
            "jsonrpc": "2.0",
            "method": "verto.modify",
            "params": [
                "action": "\(isOn ? "hold" : "unhold")",
                "dialogParams": [
                    "useStereo": true,
                    "screenShare": false,
                    "useCamera": false,
                    "useMic": true,
                    "useSpeak": true,
                    "tag": tag,
                    "localTag": nil,
                    "login": agent,
                    "videoParams": [],
                    "destination_number": VertoHelpers.REMOTE_NUMBER,
                    "caller_id_name": "",
                    "caller_id_number": "",
                    "outgoingBandwidth": "default",
                    "incomingBandwidth": "default",
                    "dedEnc": false,
                    "audioParams": [
                        "googAutoGainControl": false,
                        "googNoiseSuppression": false,
                        "googHighpassFilter": false
                    ],
                    "callID": callID,
                    "remote_caller_id_name": "Outbound Call",
                    "remote_caller_id_number": VertoHelpers.REMOTE_NUMBER
                ],
                "sessid": sessId
            ],
            "id": 4
        ])
    }
    
    static func sendDigit(agent: String, sessId: String, callID: String, number: String) -> JSON {
        let tag = UUID().uuidString.lowercased()
        return JSON([
            "jsonrpc": "2.0",
            "method": "verto.info",
            "params": [
                "dtmf": "\(number)",
                "dialogParams": [
                    "useStereo": true,
                    "screenShare": false,
                    "useCamera": false,
                    "useMic": true,
                    "useSpeak": true,
                    "tag": tag,
                    "localTag": nil,
                    "login": agent,
                    "videoParams": [],
                    "destination_number": VertoHelpers.REMOTE_NUMBER,
                    "caller_id_name": "",
                    "caller_id_number": "",
                    "outgoingBandwidth": "default",
                    "incomingBandwidth": "default",
                    "dedEnc": false,
                    "audioParams": [
                        "googAutoGainControl": false,
                        "googNoiseSuppression": false,
                        "googHighpassFilter": false
                    ],
                    "callID": callID,
                    "remote_caller_id_name": "Outbound Call",
                    "remote_caller_id_number": VertoHelpers.REMOTE_NUMBER
                ],
                "sessid": sessId
            ],
            "id": 4
        ])
    }
    
    static func blindTransfer(agent: String, sessId: String, callID: String, number: String) -> JSON {
        let tag = UUID().uuidString.lowercased()
        return JSON([
            "jsonrpc": "2.0",
            "method": "verto.modify",
            "params": [
                "action": "transfer",
                "destination": "\(number)",
                "dialogParams": [
                    "useStereo": true,
                    "screenShare": false,
                    "useCamera": false,
                    "useMic": true,
                    "useSpeak": true,
                    "tag": tag,
                    "localTag": nil,
                    "login": agent,
                    "videoParams": [],
                    "destination_number": VertoHelpers.REMOTE_NUMBER,
                    "caller_id_name": "",
                    "caller_id_number": "",
                    "outgoingBandwidth": "default",
                    "incomingBandwidth": "default",
                    "dedEnc": false,
                    "audioParams": [
                        "googAutoGainControl": false,
                        "googNoiseSuppression": false,
                        "googHighpassFilter": false
                    ],
                    "callID": callID,
                    "remote_caller_id_name": "Outbound Call",
                    "remote_caller_id_number": VertoHelpers.REMOTE_NUMBER
                ],
                "sessid": sessId
            ],
            "id": 4
        ])
    }
    
    static func callAnswer(id: Int, method: String) -> JSON {
        return JSON([
            "jsonrpc": "2.0",
            "id": id,
            "result": [
                "method": "verto.\(method)"
            ]
        ])
    }
    
    static func hangupCall(agent: String, callID: String, sessId: String) -> JSON {
        let tag = UUID().uuidString.lowercased()
        return JSON([
            "jsonrpc": "2.0",
            "method": "verto.bye",
            "params": [
                "dialogParams": [
                    "useStereo": true,
                    "screenShare": false,
                    "useMic": true,
                    "useSpeak": true,
                    "tag": tag,
                    "localTag": nil,
                    "login": agent,
                    "videoParams": [],
                    "destination_number": VertoHelpers.REMOTE_NUMBER,
                    "caller_id_name": "",
                    "caller_id_number": "",
                    "outgoingBandwidth": "default",
                    "incomingBandwidth": "default",
                    "dedEnc": false,
                    "audioParams": [
                        "googAutoGainControl": false,
                        "googNoiseSuppression": false,
                        "googHighpassFilter": false
                    ],
                    "callID": callID,
                    "remote_caller_id_name": "Outbound Call",
                    "remote_caller_id_number": VertoHelpers.REMOTE_NUMBER
                ],
                "sessid": sessId
            ],
            "id": 5
        ])
    }
}
