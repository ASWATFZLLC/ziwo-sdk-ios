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

public protocol VertoWebSocketDelegate {
    func wsVertoConnected()
    func wsVertoDisconnected()
    func vertoClientReady()
    func vertoCallStarted(callID: String, sdp: String)
    func vertoAnsweringCall(callID: String, callerName: String, sdp: String)
    func vertoCallDisplay()
    func vertoCallEnded(callID: String)
}

public class VertoWebSocket: ZiwoWebSocket {
    
    private var delegate: VertoWebSocketDelegate?
    
    var sessId: String = ""
    
    init(url: URL, delegate: VertoWebSocketDelegate) {
        super.init()
        
        self.webSocket = WebSocket(request: URLRequest(url: url))
        self.webSocket?.delegate = self
        
        self.delegate = delegate
    }
    
    func connect() {
        guard let socket = self.webSocket else {
            return
        }
        
        socket.connect()
    }
    
    func disconnect() {
        guard let socket = self.webSocket else {
            return
        }
        
        socket.disconnect()
    }
    
    // MARK: - Socket Message Parsing
    
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
    
    func parseSocketMessage(_ result: [String: String]) {
        guard let sessId = result["sessid"] else {
            return
        }
        
        self.sessId = sessId
        self.printLog(message: "[Verto WebSocket - Socket Message Parsing] > Session ID set : \(sessId)")
    }
    
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
    
    func sendLoginRequest() {
        guard let agentCCLogin = Defaults[.agentCCLogin], let agentCCPassword = Defaults[.agentCCPassword] else {
            return
        }
        
        let loginRPC = VertoHelpers.getLoginRPC(agentNumber: agentCCLogin, ccPassword: agentCCPassword)
        guard let socket = self.webSocket, let rawRPC = loginRPC.rawString() else {
            return
        }
        
        socket.write(string: rawRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > login - json RPC sent : \(rawRPC)")
        }
    }
    
    func sendCallCreation(callID: String, callRPC: String) {
        guard let socket = self.webSocket else {
            return
        }
        
        socket.write(string: callRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > create call - json RPC sent : \(callRPC)")
        }
    }
    
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
    
    func hangup(callID: String, autoDismiss: Bool) {
        guard let socket = self.webSocket, let agentEmail = Defaults[.agentEmail],
            let hangupRPC = VertoHelpers.hangupCall(agent: agentEmail, callID: callID, sessId: self.sessId).rawString() else {
                return
        }
        
        self.delegate?.vertoCallEnded(callID: callID)
        
        socket.write(string: hangupRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > hangup call - json RPC sent : \(hangupRPC)")
        }
    }
    
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
    
    func sendHoldAction(callID: String, _ isOn: Bool) {
        guard let agentEmail = Defaults[.agentEmail], let socket = self.webSocket,
            let callRPC = VertoHelpers.createHoldAction(agent: agentEmail, sessId: self.sessId, callID: callID, isOn: isOn).rawString() else {
                return
        }
        
        socket.write(string: callRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > send hold action - json RPC sent : \(callRPC)")
        }
    }
    
    func sendDigit(callID: String, number: String) {
        guard let agentEmail = Defaults[.agentEmail], let socket = self.webSocket, let callRPC = VertoHelpers.sendDigit(agent: agentEmail, sessId: self.sessId, callID: callID, number: number).rawString() else {
                return
        }
        
        socket.write(string: callRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > send digit - json RPC sent : \(callRPC)")
        }
    }
    
    func blindTransfer(callID: String, number: String) {
        guard let email = Defaults[.agentEmail], let socket = self.webSocket,
            let callRPC = VertoHelpers.blindTransfer(agent: email, sessId: self.sessId, callID: callID, number: number).rawString() else {
                return
        }
        
        socket.write(string: callRPC) {
            self.printLog(message: "[Verto WebSocket - mod_verto] > send blind transfer - json RPC sent : \(callRPC)")
        }
    }
    
}

extension VertoWebSocket: WebSocketDelegate {
    
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

