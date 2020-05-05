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

/**
 Protocol used to display different interaction of the RTC Client.
 */
protocol RTCClientDelegate: class {
    /// Describe the generation of a specific message (`answer` or`offer`)
    func logMessage(_ message: RTCMessage)
    /// Triggered when the RTC Client has closed or losed the connection.
    func closeConnection()
}

/**
 Error structure used to check validity RTC Client informations.
*/
struct RTCError {
    /// Indicates an offer has failed to be created.
    static let offerCreation: NSError = NSError(domain: "", code: 404, userInfo: ["reason": "Failed to create offer"])
    /// Indicates that the peer connection is nil.
    static let invalidPeer: NSError = NSError(domain: "", code: 404, userInfo: ["reason": "Invalid Peer"])
}

/**
 Class that manage all the RTC part of the SDK.
 It is used to setup the RTC connection of the call, generate offer/answer and handle in-call actions (mute, speaker on/off).
*/
class RTCClient: NSObject {
    
    private let stunServerURL: String = "stun:stun.l.google.com:19302"
    
    let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true"], optionalConstraints: nil)
    var peerConnection: RTCPeerConnection?
    var connectionFactory: RTCPeerConnectionFactory? = nil
    var audioLocalStream: RTCMediaStream?
    
    private let audioQueue = DispatchQueue(label: "audio")
    private let rtcAudioSession = RTCAudioSession.sharedInstance()
    private var delegate: RTCClientDelegate?

    /**
     The RTC Client initialization perfom two main tasks. It setups the RTC peer connection first then configure the RTC ausio session.
    */
    override init() {
        super.init()
        
        self.setupRTCPeerConnection()
        self.configureAudioSession()
    }
    
    /**
     Setup the RTC peer connection. RTC configuration is locked for the moment and a default stun server is provided.
     Also create an audio local stream to add it to the peer connection.
    */
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
            print("[RTCClient - Setup RTC Connection] > Unable to create local stream")
            return
        }
        
        self.peerConnection?.add(localStream)
    }
    
    /**
     Configures the audio session for the WebRTC connection setting the AVAudioSession mode to voice chat.
    */
    private func configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        } catch let error {
            print("[RTCClient - Audio Session Configuration] > Error changing AVAudioSession category: \(error)")
        }
        
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    /**
     Creates and configure a local stream that will be used linked to the peer connection.
    */
    private func createLocalStream() -> RTCMediaStream? {
        guard let factory = self.connectionFactory else {
            print("[RTCClient - Create Local Stream] > No connection factory available - nil")
            return nil
        }
        
        let localStream = factory.mediaStream(withStreamId: UUID().uuidString)
        let audioTrack = factory.audioTrack(withTrackId: UUID().uuidString)
        localStream.addAudioTrack(audioTrack)
        
        return localStream
    }
    
    /**
     Add or remove local stream to the peer connection that enable microphone input.
     
     - Parameters:
        - enabled: Boolean that defines weither the microphone is enabled or not.
    */
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
    
    // MARK: - SDP Handlers
    
    /**
     Sets a SDP (`RTCSessionDescription`) as local session description.
     
     - Parameters:
        - sessionDescription: The SDP that will be set as local SDP.
    */
    func setLocalDescription(sessionDescription: RTCSessionDescription) {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        peerConnection.setLocalDescription(sessionDescription, completionHandler: { (error) in
            guard error == nil else {
                print("[RTCClient - Set Local SDP] > Local description failed: \(error?.localizedDescription ?? "")")
                return
            }
            
            if sessionDescription.type == .offer {
                self.delegate?.logMessage(RTCOfferMessage(sdp: sessionDescription.sdp).parsePayload())
            } else {
                self.delegate?.logMessage(RTCAnswerMessage(sdp: sessionDescription.sdp).parsePayload())
            }
        })
    }
    
    /**
     Sets a SDP (`RTCSessionDescription`) as remote session description.
     
     - Parameters:
         - type: Is either an `.Offer` or `.Answer` according to the RTC Message.
         - sdp: The SDP that will be set as local SDP.
    */
    func setRemoteDescription(type: RTCSdpType, sdp: String) {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        let sessionDescription = RTCSessionDescription(type: type, sdp: sdp)
        
        peerConnection.setRemoteDescription(sessionDescription) { (error) in
            guard error == nil else {
                print("[RTCClient - Set Remote SDP] > Remote description failed: \(error?.localizedDescription ?? "")")
                return
            }
            
            if sessionDescription.type == .offer {
                self.createAnswer()
            }
        }
    }
    
    /**
     Uses the WebRTC peer connection to create an answer in order to respond to a received offer and initialize a call.
     */
    func createAnswer() {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        peerConnection.answer(for: self.mediaConstraints) { (sessionDescription, error) in
            guard error == nil else {
                print("[RTCClient - Answer Creation] > Failed to create answer: \(error?.localizedDescription ?? "")")
                return
            }
            
            guard sessionDescription != nil else {
                print("[RTCClient - Answer Creation] > No SDP found")
                return
            }
            
            self.setLocalDescription(sessionDescription: sessionDescription!)
        }
    }
    
    /**
     Uses the WebRTC peer connection to create an offer in order to initiate a call.
     
     - Returns: A promise that is fulfilled when the offer is successfully created and the local SDP has been setted.
    */
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
    
    /**
     Adds a candidate to the peer connection.
    */
    private func addCandidate(candidateMessage: RTCCandidateMessage) {
        guard let peerConnection = self.peerConnection else {
            return
        }
        
        let iceCanditate = RTCIceCandidate(sdp: candidateMessage.candidate, sdpMLineIndex: candidateMessage.label, sdpMid: candidateMessage.id)
        peerConnection.add(iceCanditate)
    }
    
}

extension RTCClient: RTCClientDelegate {
    
    func logMessage(_ message: RTCMessage) {
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

// MARK: - Audio control

/**
 RTC Client audio control.
*/
extension RTCClient {
    
    /**
     Fallback to the default playing device: headphones / bluetooth / ear speaker.
    */
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
    
    /**
     Set audio configuration to speaker.
    */
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
