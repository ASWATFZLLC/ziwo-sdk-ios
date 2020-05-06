//
//  ZiwoWebSocket.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 23/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import Starscream

/**
 ZiwoWebSocket is the parent class of `DomainWebSocket` and `VertoWebSocket` that contain the web socket of those two classes.
 It also have a boolean that can be set in the child classes to activate or deactivate the logs.
 */
public class ZiwoWebSocket {
    
    /// The websocket connected to `Verto` or the `Ziwo domain`.
    internal var webSocket: WebSocket?
    /// Boolean that activate / deactivate the debug mode.
    internal var debug: Bool = true
    
    // MARK: - Utils Methods
    
    /**
     Parent method that prints log of `VertoWebSocket` and `DomainWebSocket` classes.
     
     - Parameters:
        - message: Message to display in console.
     */
    func printLog(message: String) {
        if self.debug {
            print(message)
        }
    }
    
}
