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
    
    internal let rtcClient = RTCClient.init()
    internal var speakerState: Bool = false
    internal var isPaused: Bool = false
    internal var isMuted: Bool = false
    
    public var callID: String = ""
    public var sessID: String = ""
    public var callerName: String = ""
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
