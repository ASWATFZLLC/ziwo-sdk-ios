//
//  Call.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

/**
 Represent each call that agent will pass or receive.
 */
public class Call {
    
    /// Instance of RTC Client. Each call has one RTC Client attached.
    internal let rtcClient = RTCClient.init()
    /// Speaker state (on speaker or internal earphone).
    internal var speakerState: Bool = false
    /// Is the call on hold state or not.
    internal var isPaused: Bool = false
    /// Is the microphone muted on this call or not.
    internal var isMuted: Bool = false
    
    /// ID of the call
    public var callID: String = ""
    /// Verto session ID to which the call is linked.
    public var sessID: String = ""
    /// Name of the caller.
    public var callerName: String = ""
    /// Name of the recipient.
    public var recipientName: String = ""
    
    /**
    Initializes a new call according to given informations.

    - Parameters:
       - callID: ID of the call (`callID` is a UUID generated randomly during call creation).
       - sessID: The session ID of the logged agent. This value is stored in `VertoWebSocket` class.
       - callerName: Name of the caller.
       - recipientName: Name of the recipient.

    - Returns: A Ziwo call object.
    */
    public init(callID: String, sessID: String, callerName: String, recipientName: String) {
        self.callID = callID
        self.sessID = sessID
        self.callerName = callerName
        self.recipientName = recipientName
    }
    
    /**
     Method to set activity of the microphone during a call.
     
     - Parameters:
        - value: Boolean that defines the microphone activity.
     */
    public func setMicrophoneEnabled(_ value: Bool) {
        self.rtcClient.setMicrophoneEnabled(value)
    }
    
    
    /**
     Switch the audio call on speaker.
     */
    public func setSpeakerOn() {
        self.rtcClient.speakerOn()
    }
    
    
    /**
     Switch the audio call on internal speaker.
     */
    public func setSpeakerOff() {
        self.rtcClient.speakerOff()
    }
}
