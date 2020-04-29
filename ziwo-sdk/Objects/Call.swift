//
//  Call.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

public class Call {
    
    internal let rtcClient = RTCClient.init()
    
    public var callID: String = ""
    public var sessID: String = ""
    public var callerName: String = ""
    public var recipientName: String = ""
    
    public init(callID: String, sessID: String, callerName: String, recipientName: String) {
        self.callID = callID
        self.sessID = sessID
        self.callerName = callerName
        self.recipientName = recipientName
    }
}
