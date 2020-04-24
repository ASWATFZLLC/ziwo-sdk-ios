//
//  RTCCandidateMessage.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

struct RTCCandidateMessage {
    let type: RTCMessageType = .candidate
    let candidate: String
    let id: String
    let label: Int32
}

extension RTCCandidateMessage: RTCMessageBuilderProtocol {
    func buildMessage() -> RTCMessage {
        var payload: [String: Any] = [String: Any]()
        payload["type"] = type.rawValue
        payload["candidate"] = candidate
        payload["id"] = id
        payload["label"] = label
        return RTCMessage(payload: payload)
    }
}

extension RTCCandidateMessage: RTCMessageParserProtocol {
    typealias RTCSpecificMessage = RTCCandidateMessage
    
    static func parse(payload: [String : Any]) -> RTCCandidateMessage? {
        guard let payloadCandidate = payload["candidate"] as? String else {
            print("No candidate inside candidate message")
            return nil
        }
        
        guard let payloadId = payload["id"] as? String else {
            print("No id inside candidate message")
            return nil
        }
        
        guard let payloadLabel = payload["label"] as? Int32 else {
            print("No id inside candidate message")
            return nil
        }
        
        return RTCCandidateMessage(candidate: payloadCandidate, id: payloadId, label: payloadLabel)
    }
}
