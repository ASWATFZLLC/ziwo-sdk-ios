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

protocol VertoWebSocketDelegate {
    // Websocket related functions
    func wsVertoConnected()
    func wsVertoDisconnected()
    
    // Verto related functions
    func vertoCallStarted(callID: String, sdp: String)
    func vertoAnsweringCall(callID: String, callerName: String, sdp: String)
    func vertoCallDisplay()
    func vertoCalledEnded(callID: String)
}

public class VertoWebSocket: ZiwoWebSocket {
    
    private var delegate: VertoWebSocketDelegate?
    private var sessionID: String = ""
    
    // MARK: - Initializer
    
    init(url: URL, delegate: VertoWebSocketDelegate) {
        super.init()
        
        self.webSocket = WebSocket(request: URLRequest(url: url))
        self.webSocket?.delegate = self
        
        self.delegate = delegate
    }
    
    // MARK: - WebSocket methods
    
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
        self.delegate?.wsVertoDisconnected()
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
        
        self.sessionID = sessId
        self.printLog(message: "[WebSocket - Socket Message Parsing] > Session ID set : \(sessId)")
    }
    
    func parseVertoEvent(_ method: String, _ id: Int, _ params: [String: Any]) {
        guard let event = VertoEvent(rawValue: method) else {
            return
        }

        switch event {
        case .ClientReady:
            self.printLog(message: "[WebSocket - Socket Message Parsing] > Verto client is ready")
        case .Media:
            self.printLog(message: "[WebSocket - Socket Message Parsing] > Call creation succeed")
            self.sendCallAnswer(id, params as! [String: String])
        case .Invite:
            self.printLog(message: "[WebSocket - Socket Message Parsing] > Call from outside received")
            self.sendBackInvite(id, params as! [String: String])
        case .Display:
            self.printLog(message: "[WebSocket - Socket Message Parsing] > Display call")
            self.sendBackDisplay(id)
        case .Bye:
            self.printLog(message: "[WebSocket - Socket Message Parsing] > Call has ended")
            self.delegate?.vertoCalledEnded(callID: JSON(params)["callID"].stringValue)
        }
    }
    
    // MARK: - Mod_verto Methods
    
    func sendLoginRequest() {
        guard let ccLogin = Defaults[.agentCCLogin], let ccPassword = Defaults[.agentCCPassword] else {
            return
        }

        let loginRPC = VertoHelpers.getLoginRPC(agentNumber: ccLogin, ccPassword: ccPassword)
        guard let socket = self.webSocket, let rawRPC = loginRPC.rawString() else {
            return
        }

        socket.write(string: rawRPC) {
            self.printLog(message: "[WebSocket - mod_verto] > login - json RPC sent : \(rawRPC)")
        }
    }
    
    func sendCallCreation(callID: String, callRPC: String) {
        guard let socket = self.webSocket else {
            return
        }

        socket.write(string: callRPC) {
            self.printLog(message: "[WebSocket - mod_verto] > create call - json RPC sent : \(callRPC)")
        }
    }
    
    func sendCallAnswer(_ id: Int, _ params: [String: String]) {
        let callAnswer = VertoHelpers.callAnswer(id: id, method: "media")
        guard let socket = self.webSocket, let rawRPC = callAnswer.rawString() else {
            return
        }

        self.delegate?.vertoCallStarted(callID: JSON(params)["callID"].stringValue, sdp: JSON(params)["sdp"].stringValue)

        socket.write(string: rawRPC) {
            self.printLog(message: "[WebSocket - mod_verto] > call answer - json RPC sent : \(rawRPC)")
        }
    }
    
    func hangup(callID: String, autoDismiss: Bool) {
        guard let socket = self.webSocket, let agentEmail = Defaults[.agentEmail],
            let hangupRPC = VertoHelpers.hangupCall(agent: agentEmail, callID: callID, sessId: self.sessionID).rawString() else {
                return
        }

        self.delegate?.vertoCalledEnded(callID: callID)

        socket.write(string: hangupRPC) {
            self.printLog(message: "[WebSocket - mod_verto] > hangup call - json RPC sent : \(hangupRPC)")
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
            self.printLog(message: "[WebSocket - mod_verto] > send back call invite - json RPC sent : \(callInviteRPC)")
        }
    }
    
    func sendBackDisplay(_ id: Int) {
        let callDisplay = VertoHelpers.callAnswer(id: id, method: "display")
        guard let socket = self.webSocket, let callDisplayRPC = callDisplay.rawString() else {
            return
        }

        self.delegate?.vertoCallDisplay()
        
        socket.write(string: callDisplayRPC) {
            self.printLog(message: "[WebSocket - mod_verto] > send back call display - json RPC sent : \(callDisplayRPC)")
        }
    }
    
}

// MARK: - Verto Web Socket Delegate

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
