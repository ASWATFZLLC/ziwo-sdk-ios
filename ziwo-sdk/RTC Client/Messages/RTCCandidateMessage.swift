//
//  RTCCandidateMessage.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

/**
 Type used to handle RTC Candidates received by GoogleRTC external lib.
 */
struct RTCCandidateMessage {
    /// Type of the message
    let type: RTCMessageType = .candidate
    /// Candidate's SDP
    let candidate: String
    /// Candidate's ID
    let id: String
    /// Candidate's name
    let label: Int32
}

extension RTCCandidateMessage: RTCMessageBuilderProtocol {
    
    /**
     Format a RTC payload into a RTC Candidate Message given to informations.
     
     - Returns: A RTC Message with `.Candidate` type.
    */
    func parsePayload() -> RTCMessage {
        var payload: [String: Any] = [String: Any]()
        
        payload["type"] = self.type.rawValue
        payload["candidate"] = self.candidate
        payload["id"] = self.id
        payload["label"] = self.label
        
        return RTCMessage(payload: payload)
    }
}

extension RTCCandidateMessage: RTCMessageParserProtocol {
    
    /**
     Parse Swift dictionnary `[String: Any]` to instantiate a RTC Candidate Message.
     
     - Returns: A RTC Candidate Message.
    */
    static func parse(payload: [String : Any]) -> RTCCandidateMessage? {
        
        guard let payloadCandidate = payload["candidate"] as? String else {
            print("[RTC Client - RTC Candidate Message] > Unable to find candidate in payload...")
            return nil
        }
        
        guard let payloadId = payload["id"] as? String else {
            print("[RTC Client - RTC Candidate Message] > Unable to find an id in payload...")
            return nil
        }
        
        guard let payloadLabel = payload["label"] as? Int32 else {
            print("[RTC Client - RTC Candidate Message] > Unable to find a label in payload...")
            return nil
        }
        
        return RTCCandidateMessage(candidate: payloadCandidate, id: payloadId, label: payloadLabel)
    }
}
