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
    
    // MARK: - Web Sockets
    
    public var vertoWebSocket: VertoWebSocket?
    public var domainWebSocket: DomainWebSocket?
    
    // MARK: - Vars
    
    var delegate: ZiwoSDKDelegate?
    
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
    
    public convenience init(domain: String, accessToken: String) {
        self.init()
        
        Defaults[.domain] = domain
        Defaults[.accessToken] = accessToken
        
        self.initializeVertoWebSocket(with: domain)
        self.initializeDomainWebSocket(with: domain)
    }
    
    private func initializeVertoWebSocket(with domain: String) {
        if self.vertoWebSocket != nil {
            self.vertoWebSocket?.disconnect()
            self.vertoWebSocket = nil
        }
        
        if let vertoSocketUrl = URL(string: "wss://\(Defaults[.domain])-api.aswat.co:8082/") {
            self.vertoWebSocket = VertoWebSocket(url: vertoSocketUrl, delegate: self)
            self.vertoWebSocket?.connect()
        }
    }
    
    private func initializeDomainWebSocket(with domain: String) {
        if self.domainWebSocket != nil {
            self.domainWebSocket?.disconnect()
            self.domainWebSocket = nil
        }
        
        if let accessToken = Defaults[.accessToken] {
            if let domainSocketUrl = URL(string: "wss://\(Defaults[.domain])-api.aswat.co/socket/?access_token=\(accessToken)&EIO=3&transport=websocket") {
                self.domainWebSocket = DomainWebSocket(url: domainSocketUrl, delegate: self)
                self.domainWebSocket?.connect()
            }
        }
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
