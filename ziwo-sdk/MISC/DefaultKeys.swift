//
//  DefaultKeys.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 23/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import Defaults

extension Defaults.Keys {
    // Agent Related
    static let agentEmail = Key<String?>("agentEmail", default: "")
    static let agentCCLogin = Key<String?>("agentCCLogin", default: "")
    static let agentCCPassword = Key<String?>("agentCCPassword", default: "")
    
    // API Related
    static let domain = Key<String>("domain", default: "")
    static let accessToken = Key<String?>("accessToken", default: "")
}
