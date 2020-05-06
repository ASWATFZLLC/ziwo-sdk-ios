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


/**
 The ZiwoSDK class is a singleton that is mainly use to retrieve Ziwo related datas once the Agent is logged.
 */
public class ZiwoSDK {
    
    // MARK: - Singleton
    
    /// Easy way to access the class.
    static public var shared: ZiwoSDK = {
        return ZiwoSDK()
    }()
    
    // MARK: - Vars
    
    /// Ziwo domain to which the agent is logged on.
    public var domain: String? {
        /**
         Uses UserDefaults to return the Ziwo domain.
        */
        get {
            Defaults[.domain]
        }
        /**
         Uses UserDefaults to set the Ziwo domain.
         
         - Parameters:
            - domain: The Ziwo domain.
        */
        set(domain) {
            Defaults[.domain] = domain
        }
    }
    
    /// Access token of the logged agent.
    public var accessToken: String? {
        /**
         Uses UserDefaults to return the access token of the logged agent.
        */
        get {
            return Defaults[.accessToken]
        }
        /**
         Uses UserDefaults to set the access token of the logged agent.
         
         - Parameters:
            - accessToken: The access token of the agent returned by `.POST /auth/login`.
        */
        set(accessToken) {
            Defaults[.accessToken] = accessToken
        }
    }
    
    /// Logged agent.
    public var agent: Agent?
    
    // MARK: - Initialization Methods
    
    /**
     Public initialization
     */
    public init() { }
    
    /**
     Sets the agent in both UserDefaults and ZiwoSDK singleton class.
    */
    public func setAgent(agent: Agent) {
        self.agent = agent
        
        Defaults[.agentEmail] = agent.email
        Defaults[.agentCCLogin] = agent.ccLogin
        Defaults[.agentCCPassword] = agent.ccPassword
    }
    
    /**
     Method that will have to be called after logging out an agent to clear all datas.
    */
    public func clearAgent() {
        Defaults[.accessToken] = nil
        Defaults[.agentEmail] = nil
        Defaults[.agentCCLogin] = nil
        Defaults[.agentCCPassword] = nil
    }
    
}
