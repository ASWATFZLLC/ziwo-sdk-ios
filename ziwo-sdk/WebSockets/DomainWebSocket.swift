//
//  DomainWebSocket.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 23/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import Starscream

protocol DomainWebSocketDelegate {
    func wsDomainConnected()
    func wsDomainDisconnected()
}

public class DomainWebSocket: ZiwoWebSocket {
    
    private var delegate: DomainWebSocketDelegate?
    private var timer: Timer?
    
    // MARK: - Initializer
    
    init(url: URL, delegate: DomainWebSocketDelegate) {
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
        self.delegate?.wsDomainDisconnected()
    }
    
    // MARK: - Ping pong Methods
    
    func triggerPingTimer() {
        if let _ = self.timer {
            self.invalidatePingTimer()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 25.0) {
            self.timer = Timer.scheduledTimer(timeInterval: 25.0, target: self, selector: #selector(self.sendPing), userInfo: nil, repeats: true)
            self.timer?.fire()
        }
    }
    
    func invalidatePingTimer() {
        guard let timer = self.timer else {
            return
        }
        
        timer.invalidate()
    }
    
    // MARK: - OBJC Methods
    
    @objc func sendPing() {
        guard let socket = self.webSocket else {
            return
        }
        
        socket.write(string: "2") {
            self.printLog(message: "[Domain WebSocket - Web Socket Delegate] > Send ping ...")
        }
    }
    
}

// MARK: - Domain Web Socket Delegate

extension DomainWebSocket: WebSocketDelegate {
    
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(_):
            self.printLog(message: "[Domain WebSocket - Web Socket Delegate] > Socket connected!")
            self.delegate?.wsDomainConnected()
            self.triggerPingTimer()
        case .disconnected(_, _):
            self.printLog(message: "[Domain WebSocket - Web Socket Delegate] > Socket disconnected!")
            self.delegate?.wsDomainDisconnected()
            self.invalidatePingTimer()
        case .text(let message):
            self.printLog(message: "[Domain WebSocket - Web Socket Delegate] > Socket received a message ... : \(message)")
        default:
            return
        }
    }
    
}
