//
//  RTCOfferMessage.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

/**
 Type used to handle RTC Candidates received by GoogleRTC external lib.
*/
struct RTCOfferMessage {
    /// Type of the message
    let type: RTCMessageType = .offer
    /// Candidate's SDP
    let sdp: String
}

extension RTCOfferMessage: RTCMessageBuilderProtocol {
    
    /**
     Format a RTC payload into a RTC Offer Message given to informations.
     
     - Returns: A RTC Message with `.Offer` type.
    */
    func parsePayload() -> RTCMessage {
        var payload: [String: Any] = [String: Any]()
        
        payload["type"] = self.type.rawValue
        payload["sdp"] = self.sdp
        
        return RTCMessage(payload: payload)
    }
}

extension RTCOfferMessage: RTCMessageParserProtocol {
    
    /**
     Parse Swift dictionnary `[String: Any]` to instantiate a RTC Offer Message.
     
     - Returns: A RTC Offer Message.
    */
    static func parse(payload: [String : Any]) -> RTCOfferMessage? {
        
        guard let payloadSDP = payload["sdp"] as? String else {
            print("[RTC Client - RTC Offer Message] > No sdp inside offer message")
            return nil
        }
        
        return RTCOfferMessage(sdp: payloadSDP)
    }
}
