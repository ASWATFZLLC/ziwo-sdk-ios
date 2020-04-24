//
//  RTCOfferMessage.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

struct RTCOfferMessage {
    let type: RTCMessageType = .offer
    let sdp: String
}

extension RTCOfferMessage: RTCMessageBuilderProtocol {
    func buildMessage() -> RTCMessage {
        var payload: [String: Any] = [String: Any]()
        payload["type"] = type.rawValue
        payload["sdp"] = sdp
        return RTCMessage(payload: payload)
    }
}

extension RTCOfferMessage: RTCMessageParserProtocol {
    typealias RTCSpecificMessage = RTCOfferMessage
    
    static func parse(payload: [String : Any]) -> RTCOfferMessage? {
        guard let payloadSDP = payload["sdp"] as? String else {
            print("No sdp inside offer message")
            return nil
        }
        
        return RTCOfferMessage(sdp: payloadSDP)
    }
}
