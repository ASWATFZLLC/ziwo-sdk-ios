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

protocol ZiwoSDKDelegate {
    func vertoIsConnected()
    func vertoIsDisconnected()
    func vertoCallEnded()
    
    func domainIsConnected()
    func domainIsDisconnected()
}

public class ZiwoSDK {
    
    // MARK: - Singleton
    
    static public var shared: ZiwoSDK = {
        return ZiwoSDK()
    }()
    
    // MARK: - Web Sockets
    
    public var vertoWebSocket: VertoWebSocket?
    public var domainWebSocket: DomainWebSocket?
    
    // MARK: - Vars
    
    var delegate: ZiwoSDKDelegate?
    
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
    
    public var vertoDebug: Bool = true {
        didSet(bool) {
            guard let vertoWS = self.vertoWebSocket else {
                return
            }
            
            vertoWS.debug = bool
        }
    }
    
    public var domainDebug: Bool = true {
        didSet(bool) {
            guard let domainWS = self.domainWebSocket else {
                return
            }
            
            domainWS.debug = bool
        }
    }
    
    // MARK: - Initialization Methods
    
    public init() { }
    
    public func initializeSDK() {
        self.initializeVertoWebSocket()
        self.initializeDomainWebSocket()
    }
    
    private func initializeVertoWebSocket() {
        if self.vertoWebSocket != nil {
            self.vertoWebSocket?.disconnect()
            self.vertoWebSocket = nil
        }
        
        if let domain = self.domain,
            let vertoSocketUrl = URL(string: "wss://\(domain)-api.aswat.co:8082/") {
            self.vertoWebSocket = VertoWebSocket(url: vertoSocketUrl, delegate: self)
            self.vertoWebSocket?.connect()
        }
    }
    
    private func initializeDomainWebSocket() {
        if self.domainWebSocket != nil {
            self.domainWebSocket?.disconnect()
            self.domainWebSocket = nil
        }
        
        if let domain = self.domain, let accessToken = self.accessToken {
            if let domainSocketUrl = URL(string: "wss://\(domain)-api.aswat.co/socket/?access_token=\(accessToken)&EIO=3&transport=websocket") {
                self.domainWebSocket = DomainWebSocket(url: domainSocketUrl, delegate: self)
                self.domainWebSocket?.connect()
            }
        }
    }
    
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

extension ZiwoSDK: VertoWebSocketDelegate {
    
    func vertoCallStarted(callID: String, sdp: String) {
        
    }
    
    func vertoAnsweringCall(callID: String, callerName: String, sdp: String) {
        
    }
    
    func vertoCallDisplay() {
        
    }
    
    func wsVertoConnected() {
        self.delegate?.vertoIsConnected()
    }
    
    func wsVertoDisconnected() {
        self.delegate?.vertoIsDisconnected()
    }
    
    func vertoCalledEnded(callID: String) {
        self.delegate?.vertoCallEnded()
    }
    
}

extension ZiwoSDK: DomainWebSocketDelegate {
    
    func wsDomainConnected() {
        self.delegate?.domainIsConnected()
    }
    
    func wsDomainDisconnected() {
        self.delegate?.domainIsDisconnected()
    }
    
}
