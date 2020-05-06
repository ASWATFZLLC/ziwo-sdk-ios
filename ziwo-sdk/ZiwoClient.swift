//
//  ZiwoClient.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

/**
 `ZiwoClientDelegate` protocol will both notify about websocket connections state and call events.
*/
public protocol ZiwoClientDelegate {
    
    // MARK: - Verto Related
    
    /// Triggered when Verto is connected
    func vertoIsConnected()
    /// Triggered when Verto is disconnected
    func vertoIsDisconnected()
    /// Triggered when Verto has been fully initialized and is ready.
    func vertoClientIsReady()
    /// Triggered when a call has successfully started.
    func vertoCallStarted()
    /// Triggered when the agent receive a incoming call.
    func vertoReceivedCall(callerID: String)
    /// Triggered when the call is terminated.
    func vertoCallEnded()
}

/**
 `ZiwoClient` is the main class of the SDK. Through this class, the websocket that will be used to communicate with Verto will be initialized.
 The delegates will tell the developper when a call is received, when a call starts and when a call is terminated. It also provide informations about websocket that is linked to the `Verto` protocol.
*/
public class ZiwoClient {
    
    // MARK: - Verto Web Socket
    
    /// Instance of `VertoWebSocket` to communicate with `Verto` protocol.
    public var vertoWebSocket: VertoWebSocket?
    
    // MARK: - Vars
    
    /// `ZiwoClientDelegate` protocol will both notify about websocket connections state and call events.
    public var delegate: ZiwoClientDelegate?
    /// List of actives calls.
    public var calls: [Call] = []
    
    /// Boolean that define whether the debug logs of Verto websocket has to be displayed in console or not.
    public var vertoDebug: Bool = true {
        willSet(bool) {
            guard let vertoWS = self.vertoWebSocket else {
                return
            }
            
            vertoWS.debug = bool
        }
    }
    
    // MARK: - Initialization Methods
    
    /**
     Public `ZiwoClient` initilizer.
     */
    public init() { }
    
    /**
     Method that initialize and configure the Ziwo client.
     */
    public func initializeClient() {
        self.initializeVertoWebSocket()
    }
    
    /**
     Private method that instanciate `VertoWebSocket` and connect it to the correct endpoint based on the Ziwo domain.
     */
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
    
    /**
     Call an agent or an external number (has to be in international format).
     Automatically instantiate a call and setup a RTC connection, create an offer then format a JSON RPC to communicate with Verto protocol.
     
     - Parameters:
        - number: Number to call
    */
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
    
    /**
     Hangup a call.
     
     - Parameters:
        - callID: ID of the call to hangup
    */
    public func hangUp(callID: String) {
        guard let socket = self.vertoWebSocket else {
            return
        }
        
        socket.hangup(callID: callID)
    }
    
    /**
     Answer an incoming call.
     
     - Parameters:
        - callID: ID of the call to hangup
    */
    public func answerIncomingCall(callID: String) {
        guard let agentEmail = ZiwoSDK.shared.agent?.email, let socket = self.vertoWebSocket, let call = self.findCall(callID: callID),
            let sdp = call.rtcClient.peerConnection?.localDescription?.sdp, let callRPC = VertoHelpers.createCallRPC(method: "answer",
                agentEmail: agentEmail, sdp: sdp, sessId: socket.sessId, callID: callID).rawString() else {
                    return
        }

        socket.sendCallCreation(callRPC: callRPC)
    }
    
    // MARK: - In-Call Methods
    
    /**
     Define the state of the speaker mode (activated / deactivated).
     
     - Parameters:
         - callID: ID of the call.
         - value: Boolean that define the state of the speaker mode.
    */
    public func setSpeakerEnabled(callID: String, _ value: Bool) {
        guard let call = self.findCall(callID: callID) else {
            return
        }
        
        call.speakerState = value
        value ? call.setSpeakerOn() : call.setSpeakerOff()
    }
    
    /**
     Define the state of the microphone (activated / deactivated).
     
     - Parameters:
         - callID: ID of the call.
         - value: Boolean that define the state of the microphone.
    */
    public func setMuteEnabled(callID: String, _ value: Bool) {
        guard let call = self.findCall(callID: callID) else {
            return
        }
        
        call.isMuted = value
        call.setMicrophoneEnabled(!value)
    }
    
    /**
     Method to modify the state of the call to hold or unhold.
     
     - Parameters:
         - callID: ID of the call.
         - value: Boolean that define the state of the call (hold / unhold).
    */
    public func setPauseEnabled(callID: String, _ value: Bool) {
        guard let socket = self.vertoWebSocket, let call = self.findCall(callID: callID) else {
            return
        }
        
        call.isPaused = value
        socket.sendHoldAction(callID: callID, value)
    }
    
    // MARK: - Client Utils Methods
    
    /**
     To know if the speaker mode is enabled or not.
     
     - Parameters:
         - callID: ID of the call.
     
     - Returns: A boolean that defines if the speaker mode is enabled.
    */
    public func isSpeakerOn(callID: String) -> Bool {
        guard let call = self.findCall(callID: callID) else {
            return false
        }
        
        return call.speakerState
    }
    
    /**
     To know if the call is on hold state.
     
     - Parameters:
         - callID: ID of the call.
     
     - Returns: A boolean that defines if the call is held or not.
    */
    public func isPaused(callID: String) -> Bool {
        guard let call = self.findCall(callID: callID) else {
            return false
        }
        
        return call.isPaused
    }
    
    /**
     To know if the microphone is muted for this call.
     
     - Parameters:
         - callID: ID of the call.
     
     - Returns: A boolean that defines if the microphone is muted.
    */
    public func isMuteOn(callID: String) -> Bool {
        guard let call = self.findCall(callID: callID) else {
            return false
        }
        
        return call.isMuted
    }
    
    /**
     Allow user to retrieve a call in the active call list.
     
     - Parameters:
         - callID: ID of the call.
     
     - Returns: An active call based on its ID.
    */
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
