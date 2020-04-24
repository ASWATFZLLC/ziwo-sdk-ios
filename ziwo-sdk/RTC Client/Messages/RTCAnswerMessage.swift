//
//  RTCAnswerMessage.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

struct RTCAnswerMessage {
    let type: RTCMessageType = .answer
    let sdp: String
}

extension RTCAnswerMessage: RTCMessageBuilderProtocol {
    func buildMessage() -> RTCMessage {
        var payload: [String: Any] = [String: Any]()
        payload["type"] = type.rawValue
        payload["sdp"] = sdp
        return RTCMessage(payload: payload)
    }
}

extension RTCAnswerMessage: RTCMessageParserProtocol {
    typealias RTCSpecificMessage = RTCAnswerMessage
    
    static func parse(payload: [String : Any]) -> RTCAnswerMessage? {
        guard let payloadSDP = payload["sdp"] as? String else {
            print("No sdp inside answer message")
            return nil
        }
        
        return RTCAnswerMessage(sdp: payloadSDP)
    }
}
