//
//  VertoWebSocket.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 23/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON
import Defaults

/**
 Protocol that handle both websocket connection state and `Verto` callbacks during its initialization and during a lifetime of a call.
 */
public protocol VertoWebSocketDelegate {
    
    // MARK: - Web Socket Related
    
    /// Triggered when the websocket is connected.
    func wsVertoConnected()
    /// Triggered when the websocket is disconnected.
    func wsVertoDisconnected()
    
    // MARK: - Verto Protocol Related
    
    /// Triggered Verto has been initialized and is ready.
    func vertoClientReady()
    /// Triggered when a call between an agent A and agent B has started.
    func vertoCallStarted(callID: String, sdp: String)
    /// Triggered when the agent answer an incoming call.
    func vertoAnsweringCall(callID: String, callerName: String, sdp: String)
    /// Triggered when all the Verto/RTC initialization part has been done and the call is ready to be displayed.
    func vertoCallDisplay()
    /// Triggered when the call is terminated.
    func vertoCallEnded(callID: String)
}

/**
 Subclass of `ZiwoWebSocket` that uses websockets to help the communication between the protocol `Verto` and iOS.
 The class listen all the websocket messages and parses the methods sent by `Verto` in order to notify the app.
 Through this class, the user is able to call an agent, receive a call from outside, mute his microphone, switch the audio source, put the call on hold.
 */
public class VertoWebSocket: ZiwoWebSocket {
    
    /// Protocol that handle both websocket connection state and `Verto` callbacks during its initialization and during a lifetime of a call.
    private var delegate: VertoWebSocketDelegate?
    
    /// ID of the Verto session defined after a login request (`func sendLoginRequest()`)
    var sessId: String = ""
    
    /**
     Class initializer that create the websocket and connect the delegate.
     
     - Parameters:
        - url: URL of the websocket
        - delegate: Delegate to connects
     */
    init(url: URL, delegate: VertoWebSocketDelegate) {
        super.init()
        
        self.webSocket = WebSocket(request: URLRequest(url: url))
        self.webSocket?.delegate = self
        
        self.delegate = delegate
    }
    
    /**
     Connects the Verto websocket.
     */
    func connect() {
        guard let socket = self.webSocket else {
            return
        }
        
        socket.connect()
    }
    
    /**
     Disconnects the Verto websocket.
    */
    func disconnect() {
        guard let socket = self.webSocket else {
            return
        }
        
        socket.disconnect()
    }
    
    // MARK: - Socket Message Parsing
    
    /**
     This methods parses the messages received by the Verto websocket.
     It converts a string into a dictionnary in order to handle the different `Verto` methods.
     
     - Parameters:
        - message: The message received via the Verto websocket to parse and handle
    */
    func parseMessage(_ message: String) {
        guard let messageDict = VertoHelpers.convertStringToDictionary(message) else {
            return
        }
        
        if let method = messageDict["method"] as? String, let id = messageDict["id"] as? Int,
            let params = messageDict["params"] as? [String: Any] {
            self.parseVertoEvent(method, id, params)
        } else {
            if let result = messageDict["result"] as? [String: String] {
                self.parseSocketMessage(result)
            }
        }
    }
    
    /**
     Given a dictionnary received by the websocket, extract the ID of the Verto session and store it in `sessId`.
     
     - Parameters:
        - result: Dictionnary that contains the ID of the Verto session.
    */
    func parseSocketMessage(_ result: [String: String]) {
        guard let sessId = result["sessid"] else {
            return
        }
        
        self.sessId = sessId
        self.printLog(message: "[Verto WebSocket - Socket Message Parsing] > Session ID set : \(sessId)")
    }
    
    /**
     Format a Verto event from a message that have been parsed (by `func parseMessage(_ message: String)`) to handle the behavior and call the correct delegate.
     
     - Parameters:
         - method: String raw value of `VertoEvent` enum.
         - id: ID of the Verto message.
         - params: Parameters returned by the Verto protocol.
    */
    func parseVertoEvent(_ method: String, _ id: Int, _ params: [String: Any]) {
        guard let event = VertoEvent(rawValue: method) else {
            return
        }
         
        switch event {
        case .ClientReady:
            self.printLog(message: "[Verto WebSocket - Socket Message Parsing] > Client READY ! YAY !")
            self.delegate?.vertoClientReady()
        case .Media:
            self.printLog(message: "[Verto WebSocket - Socket Message Parsing] > Call creation succeed")
            self.sendCallAnswer(id, params as! [String: String])
        case .Invite:
            self.printLog(message: "[Verto WebSocket - Socket Message Parsing] > Call from outside received")
            self.sendBackInvite(id, params as! [String: String])
        case .Display:
            self.printLog(message: "[Verto WebSocket - Socket Message Parsing] > Display call")
            self.sendBackDisplay(id)
        case .Bye:
            self.printLog(message: "[Verto WebSocket - Socket Message Parsing] > Verto Bye")
            self.delegate?.vertoCallEnded(callID: JSON(params)["callID"].stringValue)
        }
    }
    
    // MARK: - Mod_verto Methods
    
    /**
     Sends a JSON RPC to Verto protocol to authenticate the agent.
     If the request if correct and successfully sent. The protocol will send a `verto.clientReady`.
    */
    func sendLoginRequest() {
        guard let agentCCLogin = Defaults[.agentCCLogin], let agentCCPassword = Defaults[.agentCCPassword] else {
            return
        }
        
        let loginRPC = VertoHelpers.getLoginRPC(ccLogin: agentCCLogin, ccPassword: agentCCPassword)
        guard let socket = self.webSocket, let rawRPC = loginRPC.rawString() else {
            return
        }
        
        socket.write(string: rawRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > login - json RPC sent : \(rawRPC)")
        }
    }
    
    /**
     Sends a JSON RPC to Verto protocol to initiate (the key `method` will have the value `invite`)
     or answer a call (`method` will have the value `answer`).
     
     - Parameters:
        - callRPC: JSON RPC generated (by `VertoHelpers.createCallRPC(method: String, agentEmail: String, sdp: String, sessId: String, callID: String`)) that will be sent to Verto protocol
    */
    func sendCallCreation(callRPC: String) {
        guard let socket = self.webSocket else {
            return
        }
        
        socket.write(string: callRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > create call - json RPC sent : \(callRPC)")
        }
    }
    
    /**
     Sends a JSON RPC to Verto protocol to initiate (the key `method` will have the value `invite`)
     or answer a call (`method` will have the value `answer`) by sending back the RPC.
     
     - Parameters:
        - callRPC: JSON RPC generated (by `VertoHelpers.createCallRPC(method: String, agentEmail: String, sdp: String, sessId: String, callID: String`)) that will be sent to Verto protocol
    */
    func sendCallAnswer(_ id: Int, _ params: [String: String]) {
        let callAnswer = VertoHelpers.callAnswer(id: id, method: "media")
        guard let socket = self.webSocket, let rawRPC = callAnswer.rawString() else {
            return
        }

        self.delegate?.vertoCallStarted(callID: JSON(params)["callID"].stringValue, sdp: JSON(params)["sdp"].stringValue)

        socket.write(string: rawRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > call answer - json RPC sent : \(rawRPC)")
        }
    }
    
    /**
     Sends a JSON RPC to Verto protocol to terminate the call.
     
     - Parameters:
        - callID: The ID of the call you want to hangup.
    */
    func hangup(callID: String) {
        guard let socket = self.webSocket, let agentEmail = Defaults[.agentEmail],
            let hangupRPC = VertoHelpers.hangupCall(agentEmail: agentEmail, callID: callID, sessId: self.sessId).rawString() else {
                return
        }
        
        self.delegate?.vertoCallEnded(callID: callID)
        
        socket.write(string: hangupRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > hangup call - json RPC sent : \(hangupRPC)")
        }
    }
    
    /**
     Sends a JSON RPC to Verto protocol to indicate that the agent is callable.
     
     - Parameters:
         - id: The ID of the previous `verto.invite` Verto request.
         - params: Dictionnary that contains incoming calls informations.
    */
    func sendBackInvite(_ id: Int, _ params: [String: String]) {
        guard let callIdName = params["caller_id_name"], let callID = params["callID"] else {
            return
        }
        
        let callInvite = VertoHelpers.callAnswer(id: id, method: "invite")
        guard let socket = self.webSocket, let callInviteRPC = callInvite.rawString() else {
            return
        }
        
        self.delegate?.vertoAnsweringCall(callID: callID, callerName: callIdName, sdp: JSON(params)["sdp"].stringValue)
        
        socket.write(string: callInviteRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > send back call invite - json RPC sent : \(callInviteRPC)")
        }
    }
    
    /**
     Sends a JSON RPC to Verto protocol to indicate that everything is set and the call is ready to be displayed.
     
     - Parameters:
         - id: The ID of the previous `verto.invite` Verto request.
    */
    func sendBackDisplay(_ id: Int) {
        let callDisplay = VertoHelpers.callAnswer(id: id, method: "display")
        guard let socket = self.webSocket, let callDisplayRPC = callDisplay.rawString() else {
            return
        }
        
        self.delegate?.vertoCallDisplay()
        
        socket.write(string: callDisplayRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > send back call display - json RPC sent : \(callDisplayRPC)")
        }
    }
    
    /**
     Sends a JSON RPC to Verto protocol to hold or unhold a call.
     
     - Parameters:
         - callID: ID of the call.
         - isOn: Boolean that indicate whether the call has to be held or unheld.
    */
    func sendHoldAction(callID: String, _ isOn: Bool) {
        guard let agentEmail = Defaults[.agentEmail], let socket = self.webSocket,
            let callRPC = VertoHelpers.createHoldAction(agentEmail: agentEmail, sessId: self.sessId, callID: callID, isOn: isOn).rawString() else {
                return
        }
        
        socket.write(string: callRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > send hold action - json RPC sent : \(callRPC)")
        }
    }
    
    /**
     Sends a JSON RPC to Verto protocol to send a digit to a call.
     
     - Parameters:
         - callID: ID of the call.
         - number: The digit that will be sent to the call.
    */
    func sendDigit(callID: String, number: String) {
        guard let agentEmail = Defaults[.agentEmail], let socket = self.webSocket, let callRPC = VertoHelpers.sendDigit(agentEmail: agentEmail, sessId: self.sessId, callID: callID, number: number).rawString() else {
                return
        }
        
        socket.write(string: callRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > send digit - json RPC sent : \(callRPC)")
        }
    }
    
    /**
     Sends a JSON RPC to Verto protocol to indicate that the call has to be transfer to a designed number.
     This is a non-attendance transfer.
     
     - Parameters:
         - callID: ID of the call.
         - number: Number to which the call will be redirected.
    */
    func blindTransfer(callID: String, number: String) {
        guard let email = Defaults[.agentEmail], let socket = self.webSocket,
            let callRPC = VertoHelpers.blindTransfer(agentEmail: email, sessId: self.sessId, callID: callID, number: number).rawString() else {
                return
        }
        
        socket.write(string: callRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > send blind transfer - json RPC sent : \(callRPC)")
        }
    }
    
}

// MARK: - Web socket delegate

extension VertoWebSocket: WebSocketDelegate {
    
    /**
     Delegate that will trigger `VertoWebSocket` delegates (websocket state, received messages from Verto protocol).
     */
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(_):
            self.printLog(message: "[Verto WebSocket - Web Socket Delegate] > Socket connected!")
            self.sendLoginRequest()
            self.delegate?.wsVertoConnected()
        case .disconnected(_, _):
            self.printLog(message: "[Verto WebSocket - Web Socket Delegate] > Socket disconnected!")
            self.delegate?.wsVertoDisconnected()
        case .text(let message):
            self.printLog(message: "[Verto WebSocket - Web Socket Delegate] > Socket received a message ... : \(message)")
            self.parseMessage(message)
        default:
            return
        }
    }
    
}

