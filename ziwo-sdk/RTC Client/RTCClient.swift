//
//  RTCClient.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import WebRTC
import PromiseKit

protocol RTCClientDelegate: class {
    func sendMessage(_ message: RTCMessage)
    func closeConnection()
}

struct RTCError {
    static let offerCreation: NSError = NSError(domain: "", code: 404, userInfo: ["reason": "Failed to create offer"])
    static let invalidPeer: NSError = NSError(domain: "", code: 404, userInfo: ["reason": "Invalid Peer"])
}

class RTCClient: NSObject {
    
    private let stunServerURL: String = "stun:stun.l.google.com:19302"
    
    let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true"], optionalConstraints: nil)
    var peerConnection: RTCPeerConnection?
    var connectionFactory: RTCPeerConnectionFactory? = nil
    var audioLocalStream: RTCMediaStream?
    
    private let audioQueue = DispatchQueue(label: "audio")
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    private var delegate: RTCClientDelegate?
    
    override init() {
        super.init()
        
        self.setupRTCPeerConnection()
        self.configureAudioSession()
    }
    
    func setupRTCPeerConnection() {
        self.delegate = self
        
        let config = RTCConfiguration()
        config.bundlePolicy = .balanced
        config.activeResetSrtpParams = true
        config.candidateNetworkPolicy = .all
        config.iceServers = [RTCIceServer(urlStrings: [stunServerURL])]
        
        self.connectionFactory = RTCPeerConnectionFactory()
        self.peerConnection = self.connectionFactory!.peerConnection(with: config, constraints: self.mediaConstraints, delegate: self)
        
        self.audioLocalStream = self.createLocalStream()
        guard let localStream = self.audioLocalStream else {
            print("Unable to create local stream")
            return
        }
        self.peerConnection?.add(localStream)
    }
    
    private func configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        } catch let error {
            print("Error changeing AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    private func createLocalStream() -> RTCMediaStream? {
        guard let factory = self.connectionFactory else {
            print("No connection factory available - nil")
            return nil
        }
        
        let localStream = factory.mediaStream(withStreamId: UUID().uuidString)
        let audioTrack = factory.audioTrack(withTrackId: UUID().uuidString)
        localStream.addAudioTrack(audioTrack)
        
        return localStream
    }
    
    // MARK: - SDP Handlers
    
    func setLocalDescription(sessionDescription: RTCSessionDescription) {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        peerConnection.setLocalDescription(sessionDescription, completionHandler: { (error) in
            guard error == nil else {
                print("Set local failed: \(error!)")
                return
            }
            
            if sessionDescription.type == .offer {
                self.delegate?.sendMessage(RTCOfferMessage(sdp: sessionDescription.sdp).buildMessage())
            } else {
                self.delegate?.sendMessage(RTCAnswerMessage(sdp: sessionDescription.sdp).buildMessage())
            }
        })
    }
    
    func setRemoteDescription(type: RTCSdpType, sdp: String) {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        let sessionDescription = RTCSessionDescription(type: type, sdp: sdp)
        
        peerConnection.setRemoteDescription(sessionDescription) { (error) in
            guard error == nil else {
                print("Remote description failed: \(error!)")
                return
            }
            
            if sessionDescription.type == .offer {
                self.createAnswer()
            }
        }
    }
    
    func createAnswer() {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        peerConnection.answer(for: self.mediaConstraints) { (sessionDescription, error) in
            guard error == nil else {
                print("Failed to create: \(error!)")
                return
            }
            
            guard sessionDescription != nil else {
                print("No session description - nil")
                return
            }
            
            self.setLocalDescription(sessionDescription: sessionDescription!)
        }
    }
    
    func createOffer() -> Promise<Void> {
        return Promise { seal in
            guard let peerConnection = self.peerConnection else {
                seal.reject(RTCError.invalidPeer)
                return
            }
            
            peerConnection.offer(for: self.mediaConstraints) { (sdp, error) in
                guard error == nil else {
                    seal.reject(RTCError.offerCreation)
                    return
                }

                self.setLocalDescription(sessionDescription: sdp!)
                seal.fulfill(())
            }
        }
        
    }
    
    private func addCandidate(candidateMessage: RTCCandidateMessage) {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        let iceCanditate = RTCIceCandidate(sdp: candidateMessage.candidate, sdpMLineIndex: candidateMessage.label, sdpMid: candidateMessage.id)
        peerConnection.add(iceCanditate)
    }
    
    public func setMicrophoneEnabled(_ enabled: Bool) {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        if enabled {
            if let localStream = self.audioLocalStream, peerConnection.localStreams.isEmpty {
                peerConnection.add(localStream)
            }
        } else {
            if let localStream = self.audioLocalStream, !peerConnection.localStreams.isEmpty {
                peerConnection.remove(localStream)
            }
        }
    }
    
}

extension RTCClient: RTCClientDelegate {
    
    func sendMessage(_ message: RTCMessage) {
        print("[RTCClient - RTC Client Delegate] > RTCClient received a message ... : \(message)")
    }
    
    func closeConnection() {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        peerConnection.close()
        self.peerConnection = nil
    }
    
}

extension RTCClient: RTCPeerConnectionDelegate {
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("[RTCClient - RTC Peer Connection Delegate] > 1")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let iceCandidate = RTCCandidateMessage(candidate: candidate.sdp, id: candidate.sdpMid!, label: candidate.sdpMLineIndex)
        self.addCandidate(candidateMessage: iceCandidate)
        print("[RTCClient - RTC Peer Connection Delegate] > Candidate found : \(iceCandidate)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("[RTCClient - RTC Peer Connection Delegate] > 2")
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("[RTCClient - RTC Peer Connection Delegate] > 3")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("[RTCClient - RTC Peer Connection Delegate] > RTC peerConnection Ice Connection State Changed : \(newState.rawValue)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("[RTCClient - RTC Peer Connection Delegate] > RTC peerConnection has new gathering state : \(newState.rawValue)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("[RTCClient - RTC Peer Connection Delegate] > 5")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("[RTCClient - RTC Peer Connection Delegate] > RTC peerConnection has new signaling state : \(stateChanged.rawValue)")
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("[RTCClient - RTC Peer Connection Delegate] > 6")
    }
    
}

// MARK:- Audio control
extension RTCClient {
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                print("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // Force speaker
    func speakerOn() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
            } catch let error {
                print("Couldn't force audio to speaker: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
}
