//
//  ZiwoSDK.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 22/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import Starscream
import Defaults

public class ZiwoSDK {
    
    // MARK: - Singleton
    
    static public var shared: ZiwoSDK = {
        return ZiwoSDK()
    }()
    
    // MARK: - Vars
    
    public var domain: String? {
        get {
            Defaults[.domain]
        }
        set(domain) {
            Defaults[.domain] = domain
        }
    }
    
    public var accessToken: String? {
        get {
            return Defaults[.accessToken]
        }
        set(accessToken) {
            Defaults[.accessToken] = accessToken
        }
    }
    
    // MARK: - Initialization Methods
    
    public init() { }
    
    public func setAgent(agent: Agent) {
        Defaults[.agentEmail] = agent.email
        Defaults[.agentCCLogin] = agent.ccLogin
        Defaults[.agentCCPassword] = agent.ccPassword
    }
    
    public func clearAgent() {
        Defaults[.accessToken] = nil
        Defaults[.agentEmail] = nil
        Defaults[.agentCCLogin] = nil
        Defaults[.agentCCPassword] = nil
    }
    
}
