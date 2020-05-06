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

/**
 Verto methods that are used during a call. To understand WebRTC negociation through SDP, please check [this website](https://tools.ietf.org/id/draft-ietf-rtcweb-sdp-08.html).
 */
enum VertoEvent: String {
    /// Triggered when the Verto client has been initialized with `(VertoWebSocket).sendLoginRequest()`.
    case ClientReady = "verto.clientReady"
    /// Triggered Verto is ready to connect the call. The payload contain a `SDP` and the `callID`.
    case Media = "verto.media"
    /// Triggered when the call has been successfully created.
    case Invite = "verto.invite"
    /// Triggered when the agent receive a call.
    case Display = "verto.display"
    /// Triggered when the call has been terminated.
    case Bye = "verto.bye"
}

/**
 This class helps to format well-formatted JSON-RPC in order to communicate with Verto protocol.
 */
class VertoHelpers {
    
    static var REMOTE_NUMBER = ""
    
    /**
     Encrypt string to md5.

     - Parameters:
       - value: The string to encrypt.

     - Returns: MD5-encrypted string.
    */
    static func toMd5(value: String) -> String {
        let data = Data(value.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /**
     Generic method that convert a string into a swift dictionary. This helps to parse messages from the Verto websocket.

     - Parameters:
       - message: String to converto to dictionary.

     - Returns: A swift dictionary based on the given message.
    */
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
    
    /**
     Format a RPC-JSON to log user on Verto.

     - Parameters:
        - ccLogin: Agent's ccLogin.
        - ccPassword: Agent's ccPassword.

     - Returns: A JSON value that will be used to log the agent on Verto.
    */
    static func getLoginRPC(ccLogin: String, ccPassword: String) -> JSON {
        guard let domain = Defaults[.domain] else {
            return JSON()
        }
        
        let password = VertoHelpers.toMd5(value: "\(ccLogin + ccPassword)")
        let sessId = UUID().uuidString.lowercased()
        
        return JSON([
            "jsonrpc": "2.0",
            "method": "login",
            "params": [
                "login": "agent-\(ccLogin)@\(domain)-api.aswat.co",
                "passwd": "\(password)",
                "sessid": "\(sessId)",
            ],
            "id": 3
        ])
    }
    
    /**
     Format a RPC-JSON to initiate either a call creation (`verto.invite`) or answer a call (`verto.answer`) on Verto.

     - Parameters:
        - method: Should be `invite` for call creation or `answer` for call answer.
        - agentEmail: The email of the agent that send this message to Verto.
        - sdp: SDP of the current agent.
        - sessId: Session ID of the Verto websocket.
        - callID: ID of the call.

     - Returns: A JSON value that will be used to create or accept a Verto call.
    */
    static func createCallRPC(method: String, agentEmail: String, sdp: String, sessId: String, callID: String) -> JSON {
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
                    "login": agentEmail,
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
    
    /**
     Format a RPC-JSON to hold or unhold a call.

     - Parameters:
        - agentEmail: The email of the agent that send this message to Verto.
        - sessId: Session ID of the Verto websocket.
        - callID: ID of the call.
        - isOn: Boolean that set the call on hold (`true`) or unhold (`false`).

     - Returns: A JSON value that will be used to handle a hold state of a call.
    */
    static func createHoldAction(agentEmail: String, sessId: String, callID: String, isOn: Bool) -> JSON {
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
                    "login": agentEmail,
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
    
    /**
     Format a RPC-JSON to send a digit to the Verto protocol via a call.

     - Parameters:
        - agentEmail: The email of the agent that send this message to Verto.
        - sessId: Session ID of the Verto websocket.
        - callID: ID of the call.
        - number: Digit that can be sent. (0 to 9, # and *)

     - Returns: A JSON value that will be used to send a digit to a Verto call.
    */
    static func sendDigit(agentEmail: String, sessId: String, callID: String, number: String) -> JSON {
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
                    "login": agentEmail,
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
    
    /**
     Format a RPC-JSON to transfer a call without attendance.

     - Parameters:
        - agentEmail: The email of the agent that send this message to Verto.
        - sessId: Session ID of the Verto websocket.
        - callID: ID of the call.
        - number: The targeted number where the call will be transfered.

     - Returns: A JSON value that will be used to transfer a call without attendance.
    */
    static func blindTransfer(agentEmail: String, sessId: String, callID: String, number: String) -> JSON {
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
                    "login": agentEmail,
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
    
    /**
     Format a RPC-JSON to indicate the Verto protocol that the agent has accepted the call.

     - Parameters:
        - id: ID of the call.
        - method: Method sent to Verto protocol.
     
     - Returns: A JSON value that will be used to communicate with Verto protocol.
    */
    static func callAnswer(id: Int, method: String) -> JSON {
        return JSON([
            "jsonrpc": "2.0",
            "id": id,
            "result": [
                "method": "verto.\(method)"
            ]
        ])
    }
    
    /**
     Format a RPC-JSON to terminate the call.

     - Parameters:
        - agentEmail: The email of the agent that send this message to Verto.
        - callID: ID of the call.
        - sessId: Session ID of the Verto websocket.

     - Returns: A JSON value that will be used to hangup.
    */
    static func hangupCall(agentEmail: String, callID: String, sessId: String) -> JSON {
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
                    "login": agentEmail,
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
