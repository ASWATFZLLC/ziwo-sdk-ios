//
//  ZiwoClient.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

public protocol ZiwoClientDelegate {
    
    // MARK: - Verto Related
    func vertoIsConnected()
    func vertoIsDisconnected()
    func vertoClientIsReady()
    func vertoCallStarted()
    func vertoReceivedCall(callerID: String)
    func vertoCallEnded()
}

public class ZiwoClient {
    
    // MARK: - Verto Web Socket
    
    public var vertoWebSocket: VertoWebSocket?
    
    // MARK: - Vars
    
    public var delegate: ZiwoClientDelegate?
    public var calls: [Call] = []
    
    public var vertoDebug: Bool = true {
        willSet(bool) {
            guard let vertoWS = self.vertoWebSocket else {
                return
            }
            
            vertoWS.debug = bool
        }
    }
    
    // MARK: - Initialization Methods
    
    public init() { }
    
    public func initializeClient() {
        self.initializeVertoWebSocket()
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
    
    // MARK: - Client Call Methods
    
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
                    let callRPC = VertoHelpers.createCallRPC(method: "invite", agentEmail: agentEmail, sdp: sdp, sessId: vertoWS.sessId, callID: call.callID).rawString() else {
                    return
                }

                vertoWS.sendCallCreation(callRPC: callRPC)
            }
        }.catch { error in
            print("[Ziwo SDK - Call] - Error occured while creating offer : \(error.localizedDescription)")
        }
    }
    
    public func hangUp(callID: String) {
        guard let socket = self.vertoWebSocket else {
            return
        }
        
        socket.hangup(callID: callID)
    }
    
    public func answerIncomingCall(callID: String) {
        guard let agentEmail = ZiwoSDK.shared.agent?.email, let socket = self.vertoWebSocket, let call = self.findCall(callID: callID),
            let sdp = call.rtcClient.peerConnection?.localDescription?.sdp, let callRPC = VertoHelpers.createCallRPC(method: "answer",
                agentEmail: agentEmail, sdp: sdp, sessId: socket.sessId, callID: callID).rawString() else {
                    return
        }

        socket.sendCallCreation(callRPC: callRPC)
    }
    
    // MARK: - In-Call Methods
    
    public func setSpeakerEnabled(callID: String, _ value: Bool) {
        guard let call = self.findCall(callID: callID) else {
            return
        }
        
        call.speakerState = value
        value ? call.setSpeakerOn() : call.setSpeakerOff()
    }
    
    public func setMuteEnabled(callID: String, _ value: Bool) {
        guard let call = self.findCall(callID: callID) else {
            return
        }
        
        call.isMuted = value
        call.setMicrophoneEnabled(!value)
    }
    
    public func setPauseEnabled(callID: String, _ value: Bool) {
        guard let socket = self.vertoWebSocket, let call = self.findCall(callID: callID) else {
            return
        }
        
        call.isPaused = value
        socket.sendHoldAction(callID: callID, value)
    }
    
    // MARK: - Client Utils Methods
    
    public func isSpeakerOn(callID: String) -> Bool {
        guard let call = self.findCall(callID: callID) else {
            return false
        }
        
        return call.speakerState
    }
    
    public func isPaused(callID: String) -> Bool {
        guard let call = self.findCall(callID: callID) else {
            return false
        }
        
        return call.isPaused
    }
    
    public func isMuteOn(callID: String) -> Bool {
        guard let call = self.findCall(callID: callID) else {
            return false
        }
        
        return call.isMuted
    }
    
    public func findCall(callID: String) -> Call? {
        return self.calls.filter({ $0.callID == callID }).first
    }
}


extension ZiwoClient: VertoWebSocketDelegate {
    
    // MARK: - Verto Web Socket Related
    
    public func wsVertoConnected() {
        self.delegate?.vertoIsConnected()
    }
    
    public func wsVertoDisconnected() {
        self.delegate?.vertoIsDisconnected()
    }
    
    // MARK: - Verto Protocol Related
    
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
        
        self.delegate?.vertoReceivedCall(callerID: callerName)
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
