//
//  ZiwoClient.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

protocol ZiwoClientDelegate {
    func vertoIsConnected()
    func vertoIsDisconnected()
    func vertoCallEnded()
    
    func domainIsConnected()
    func domainIsDisconnected()
}

public class ZiwoClient {
    
    // MARK: - Web Sockets
    
    public var vertoWebSocket: VertoWebSocket?
    public var domainWebSocket: DomainWebSocket?
    
    // MARK: - Vars
    
    var delegate: ZiwoClientDelegate?
    
    public var vertoDebug: Bool = true {
        willSet(bool) {
            guard let vertoWS = self.vertoWebSocket else {
                return
            }
            
            vertoWS.debug = bool
        }
    }
    
    public var domainDebug: Bool = true {
        willSet(bool) {
            guard let domainWS = self.domainWebSocket else {
                return
            }
            
            domainWS.debug = bool
        }
    }
    
    // MARK: - Initialization Methods
    
    public init() { }
    
    public func initializeClient() {
        self.initializeVertoWebSocket()
        self.initializeDomainWebSocket()
    }
    
    private func initializeVertoWebSocket() {
        if self.vertoWebSocket != nil {
            self.vertoWebSocket?.disconnect()
            self.vertoWebSocket = nil
        }
        
        if let domain = ZiwoSDK.shared.domain,
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
        
        if let domain = ZiwoSDK.shared.domain, let accessToken = ZiwoSDK.shared.accessToken {
            if let domainSocketUrl = URL(string: "wss://\(domain)-api.aswat.co/socket/?access_token=\(accessToken)&EIO=3&transport=websocket") {
                self.domainWebSocket = DomainWebSocket(url: domainSocketUrl, delegate: self)
                self.domainWebSocket?.connect()
            }
        }
    }
    
    // MARK: - Client Methods
    
    public func call(number: String) {
        guard let vertoWS = self.vertoWebSocket, let ccLogin = ZiwoSDK.shared.agent?.ccLogin,
            let agentEmail = ZiwoSDK.shared.agent?.email else {
                return
        }
        
        let call = Call(callID: UUID().uuidString.lowercased(), sessID: vertoWS.sessionID,
                        callerName: ccLogin, recipientName: number)

        call.rtcClient.createOffer().done { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                VertoHelpers.REMOTE_NUMBER = number

                guard let peerConnection = call.rtcClient.peerConnection, let sdp = peerConnection.localDescription?.sdp,
                    let callRPC = VertoHelpers.createCallRPC(method: "invite", agent: agentEmail, sdp: sdp,
                                                             sessId: vertoWS.sessionID, callID: call.callID).rawString() else {
                    return
                }

                vertoWS.sendCallCreation(callID: call.callID, callRPC: callRPC)
            }
        }.catch { error in
            print("[DialPadController - Call Processing] - Error occured while creating offer : \(error.localizedDescription)")
        }
    }
}


extension ZiwoClient: VertoWebSocketDelegate {
    
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

extension ZiwoClient: DomainWebSocketDelegate {
    
    func wsDomainConnected() {
        self.delegate?.domainIsConnected()
    }
    
    func wsDomainDisconnected() {
        self.delegate?.domainIsDisconnected()
    }
    
}
