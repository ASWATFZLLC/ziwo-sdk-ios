//
//  DefaultKeys.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 23/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import Defaults

/**
Ziwo's related datas saved in UserDefaults.
*/
extension Defaults.Keys {
    // Agent Related
    
    /// Agent's email
    static let agentEmail = Key<String?>("agentEmail", default: "")
    /// Agent's ccLogin
    static let agentCCLogin = Key<String?>("agentCCLogin", default: "")
    /// Agent's ccPassword
    static let agentCCPassword = Key<String?>("agentCCPassword", default: "")
    
    // API Related
    
    /// Ziwo domain the app is linked to
    static let domain = Key<String?>("domain", default: "")
    /// Agent's accessToken
    static let accessToken = Key<String?>("accessToken", default: "")
}
