//
//  ZiwoWebSocket.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 23/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import Starscream

public class ZiwoWebSocket {
    
    internal var webSocket: WebSocket?
    internal var debug: Bool = true
    
    // MARK: - Utils Methods
    
    func printLog(message: String) {
        if self.debug {
            print(message)
        }
    }
    
}
