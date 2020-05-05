//
//  RTCAnswerMessage.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

/**
 Type used to handle RTC Candidates received by GoogleRTC external lib.
*/
struct RTCAnswerMessage {
    /// Type of the message
    let type: RTCMessageType = .answer
    /// SDP of the message
    let sdp: String
}

extension RTCAnswerMessage: RTCMessageBuilderProtocol {
    
    /**
     Format a RTC payload into a RTC Answer Message given to informations.
     
     - Returns: A RTC Message with `.Answer` type.
    */
    func parsePayload() -> RTCMessage {
        var payload: [String: Any] = [String: Any]()
        
        payload["type"] = self.type.rawValue
        payload["sdp"] = self.sdp
        
        return RTCMessage(payload: payload)
    }
}

extension RTCAnswerMessage: RTCMessageParserProtocol {
    
    /**
     Parse Swift dictionnary `[String: Any]` to instantiate a RTC Answer Message.
     
     - Returns: A RTC Answer Message.
    */
    static func parse(payload: [String : Any]) -> RTCAnswerMessage? {
        
        guard let payloadSDP = payload["sdp"] as? String else {
            print("[RTCClient - RTC Peer Connection Delegate] > Unable to find SDP in payload")
            return nil
        }
        
        return RTCAnswerMessage(sdp: payloadSDP)
    }
}
