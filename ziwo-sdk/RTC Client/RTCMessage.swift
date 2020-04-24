//
//  RTCMessage.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

enum SocketEvent: String {
    case join = "join"
    case pong = "pong"
    case whoAmI = "whoami"
    case online = "online"
    case incoming = "incoming"
    case rejected = "rejected"
    case created = "created"
    case ready = "ready"
    case rtcMessage = "rtcmessage"
    case callRejected = "call-rejected"
    case callAnswered = "call-answered"
    case call = "call"
    case bye = "bye"
}

enum RTCMessageType: String {
    case offer = "offer"
    case answer = "answer"
    case candidate = "candidate"
    
    static func messageType(for payload: [String: Any]) -> RTCMessageType? {
        guard let typeString = payload["type"] as? String else {
            print("RTC payload with no type")
            return nil
        }
        
        return RTCMessageType(rawValue: typeString)
    }
}

protocol RTCMessageBuilderProtocol {
    func buildMessage() -> RTCMessage
}

protocol RTCMessageParserProtocol {
    associatedtype RTCSpecificMessage
    static func parse(payload: [String: Any]) -> RTCSpecificMessage?
}

struct RTCMessage {
    let event: SocketEvent = .rtcMessage
    let payload: [String: Any]
}

protocol SocketMessageData {
    associatedtype Element
    static func create(data: [Any]) -> Element?
}

extension RTCMessage: SocketMessageData {
    typealias Element = RTCMessage
    
    static func create(data: [Any]) -> RTCMessage? {
        guard let payloadDictionary = data.first as? [String: Any] else {
            print("Unable to retrieve rtc payload from socket message")
            return nil
        }
        
        return RTCMessage(payload: payloadDictionary)
    }
}


