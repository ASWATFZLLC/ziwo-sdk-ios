//
//  RTCMessage.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

/**
 Used to handle different type of message through RTC Client.
*/
enum SocketEvent: String {
    /// RTC Message
    case rtcMessage = "rtcmessage"
}

/**
 Specific type of a RTC message
*/
enum RTCMessageType: String {
    case offer = "offer"
    case answer = "answer"
    case candidate = "candidate"
}

/**
 Protocol that builds RTC Client messages to handle peer candidates & offers/answers.
*/
protocol RTCMessageBuilderProtocol {
    func parsePayload() -> RTCMessage
}

/**
 Protocol that parse GoogleRTC messages in order to build RTC messages to handle peer candidates & offers/answers.
*/
protocol RTCMessageParserProtocol {
    associatedtype RTCSpecificMessage
    static func parse(payload: [String: Any]) -> RTCSpecificMessage?
}

/**
 Protocol that parse GoogleRTC messages in order to build RTC messages to handle peer candidates & offers/answers.
*/
struct RTCMessage {
    let event: SocketEvent = .rtcMessage
    let payload: [String: Any]
}

