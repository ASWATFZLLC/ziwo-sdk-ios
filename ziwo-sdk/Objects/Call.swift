//
//  Call.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

public class Call {
    
    let rtcClient = RTCClient.init()
    
    var callID: String = ""
    var sessID: String = ""
    var callerName: String = ""
    var recipientName: String = ""
    
    public init(callID: String, sessID: String, callerName: String, recipientName: String) {
        self.callID = callID
        self.sessID = sessID
        self.callerName = callerName
        self.recipientName = recipientName
    }
}
