//
//  ZiwoClient.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

public protocol ZiwoClientDelegate {
    func vertoIsConnected()
    func vertoIsDisconnected()
    func vertoClientIsReady()
    func vertoCallStarted()
    func vertoCallEnded()
    
    func domainIsConnected()
    func domainIsDisconnected()
}

public class ZiwoClient {
    
    // MARK: - Web Sockets
    
    public var vertoWebSocket: VertoWebSocket?
    public var domainWebSocket: DomainWebSocket?
    
    // MARK: - Vars
    
    public var delegate: ZiwoClientDelegate?
    private var calls: [Call] = []
    
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
        
        let call = Call(callID: UUID().uuidString.lowercased(), sessID: vertoWS.sessId,
                        callerName: ccLogin, recipientName: number)
        self.calls.append(call)

        call.rtcClient.createOffer().done { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                VertoHelpers.REMOTE_NUMBER = number

                guard let peerConnection = call.rtcClient.peerConnection, let sdp = peerConnection.localDescription?.sdp,
                    let callRPC = VertoHelpers.createCallRPC(method: "invite", agent: agentEmail, sdp: sdp, sessId: vertoWS.sessId, callID: call.callID).rawString() else {
                    return
                }

                vertoWS.sendCallCreation(callID: call.callID, callRPC: callRPC)
            }
        }.catch { error in
            print("[Ziwo SDK - Call] - Error occured while creating offer : \(error.localizedDescription)")
        }
    }
    
    func findCall(callID: String) -> Call? {
        return self.calls.filter({ $0.callID == callID }).first
    }
}


extension ZiwoClient: VertoWebSocketDelegate {
    
    public func wsVertoConnected() {
        self.delegate?.vertoIsConnected()
    }
    
    public func wsVertoDisconnected() {
        self.delegate?.vertoIsDisconnected()
    }
    
    public func vertoClientReady() {
        self.delegate?.vertoClientIsReady()
    }
    
    public func vertoCallStarted(callID: String, sdp: String) {
        guard let call = self.findCall(callID: callID) else {
            return
        }
        
        call.rtcClient.setRemoteDescription(type: .answer, sdp: sdp)
    }
    
    public func vertoAnsweringCall(callID: String, callerName: String, sdp: String) {
        guard let socket = self.vertoWebSocket, let agentCCLogin = ZiwoSDK.shared.agent?.ccLogin else {
            return
        }
        
        let call = Call(callID: callID, sessID: socket.sessId, callerName: callerName, recipientName: agentCCLogin)
        self.calls.append(call)
        call.rtcClient.setRemoteDescription(type: .offer, sdp: sdp)
    }
    
    public func vertoCallDisplay() {
        self.delegate?.vertoCallStarted()
    }
    
    public func vertoCallEnded(callID: String) {
        guard let call = self.findCall(callID: callID) else {
            return
        }

        call.rtcClient.closeConnection()
        self.calls.removeAll(where: {$0.callID == callID})
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
