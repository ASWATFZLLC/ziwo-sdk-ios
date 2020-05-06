//
//  AgentViewController.swift
//  ZiwoExampleApp
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import UIKit
import ZiwoSDK

class AgentViewController: UIViewController {
    
    // MARK: - Vars
    
    var ziwoClient: ZiwoClient = ZiwoClient()
    
    // MARK: - UI Vars
    
    var dialPad: UITextField?
    var callButton: UIButton?
    var answerButton: UIButton?
    var speakerButton: UIButton?
    var muteButton: UIButton?
    var pauseButton: UIButton?
    
    // MARK: - Basic Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Agent View"
        self.initializeZiwoClient()
        
        self.setupUI()
    }
    
    // MARK: - Initialization Methods
    
    func initializeZiwoClient() {
        // MARK: - Initialize domain & verto websockets in viewDidLoad to be sure they're always running.

        Network.autoLogin().done { _ in
            Network.getProfile().done { agent in
                
                /** NOTE: - After those steps, the only things missing for the Ziwo SDK initialization are :
                    - Set the current agent
                    - Connect the verto websocket
                    - Connect the domain websocket
                 The two last steps will be implemented in your logged view.
                */
                ZiwoSDK.shared.setAgent(agent: agent)
                
                self.ziwoClient.vertoDebug = false
                self.ziwoClient.initializeClient()
                self.ziwoClient.delegate = self
            }.catch { error in
                print("[Example App Login] - Error while trying to fetch agent profile : \(error.localizedDescription)")
            }
        }.catch { error in
            print("[Example App Login] - Error while trying to authenticate agent : \(error.localizedDescription)")
        }
    }
    
    // MARK: - UI Methods
    
    func setupUI() {
        self.view.backgroundColor = .lightGray
        
        self.dialPad = UITextField(frame: CGRect(x: 20, y:  Frame.at(percent: 20, of: .Height, ofView: self.view),
                                                        width: self.view.frame.width - 40, height: 30))
        self.dialPad?.autocorrectionType = .no
        self.dialPad?.autocapitalizationType = .none
        self.dialPad?.keyboardType = .phonePad
        self.dialPad?.backgroundColor = .white
        self.dialPad?.textAlignment = .center
        self.dialPad?.placeholder = "+971559990000"
        self.view.addSubview(self.dialPad!)
        
        self.callButton = UIButton(frame: CGRect(x: 20, y: Frame.below(view: self.dialPad, withOffset: 20),
                                                  width: self.view.frame.width - 40, height: 30))
        self.callButton?.addTarget(self, action: #selector(self.callPressed), for: .touchUpInside)
        self.callButton?.backgroundColor = .green
        self.callButton?.titleLabel?.tintColor = .white
        self.callButton?.setTitle("Call", for: .normal)
        self.view.addSubview(self.callButton!)
        
        self.answerButton = UIButton(frame: CGRect(x: 20, y: Frame.below(view: self.callButton, withOffset: 20),
                                                  width: self.view.frame.width - 40, height: 30))
        self.answerButton?.addTarget(self, action: #selector(self.answerPressed), for: .touchUpInside)
        self.answerButton?.backgroundColor = .green
        self.answerButton?.titleLabel?.tintColor = .white
        self.answerButton?.isHidden = true
        self.view.addSubview(self.answerButton!)
        
        self.speakerButton = UIButton(frame: CGRect(x: 20, y: Frame.below(view: self.answerButton, withOffset: 20),
                                                  width: self.view.frame.width - 40, height: 30))
        self.speakerButton?.addTarget(self, action: #selector(self.speakerPressed), for: .touchUpInside)
        self.speakerButton?.setTitle("Set speaker ON", for: .normal)
        self.speakerButton?.backgroundColor = .green
        self.speakerButton?.titleLabel?.tintColor = .white
        self.speakerButton?.isHidden = true
        self.view.addSubview(self.speakerButton!)
        
        self.muteButton = UIButton(frame: CGRect(x: 20, y: Frame.below(view: self.speakerButton, withOffset: 20),
                                                  width: self.view.frame.width - 40, height: 30))
        self.muteButton?.addTarget(self, action: #selector(self.mutePressed), for: .touchUpInside)
        self.muteButton?.setTitle("Mute microphone", for: .normal)
        self.muteButton?.backgroundColor = .green
        self.muteButton?.titleLabel?.tintColor = .white
        self.muteButton?.isHidden = true
        self.view.addSubview(self.muteButton!)
        
        self.pauseButton = UIButton(frame: CGRect(x: 20, y: Frame.below(view: self.muteButton, withOffset: 20),
                                                  width: self.view.frame.width - 40, height: 30))
        self.pauseButton?.addTarget(self, action: #selector(self.pausePressed), for: .touchUpInside)
        self.pauseButton?.setTitle("Hold call", for: .normal)
        self.pauseButton?.backgroundColor = .green
        self.pauseButton?.titleLabel?.tintColor = .white
        self.pauseButton?.isHidden = true
        self.view.addSubview(self.pauseButton!)
    }
    
    func handleButtonCall(isCalling: Bool) {
        self.callButton?.backgroundColor = isCalling ? .red : .green
        self.callButton?.setTitle(isCalling ? "Hang Up" : "Call", for: .normal)
        
        self.callButton?.removeTarget(nil, action: nil, for: .allEvents)
        if isCalling {
            self.callButton?.addTarget(self, action: #selector(self.hangUpPressed), for: .touchUpInside)
        } else {
            self.callButton?.addTarget(self, action: #selector(self.callPressed), for: .touchUpInside)
        }
    }
    
    // MARK: - OBJC Methods
    
    @objc func mutePressed() {
        guard let call = self.ziwoClient.calls.first else {
            return
        }
        
        if self.ziwoClient.isMuteOn(callID: call.callID) {
            self.ziwoClient.setMuteEnabled(callID: call.callID, false)
            self.muteButton?.setTitle("Mute microphone", for: .normal)
        } else {
            self.ziwoClient.setMuteEnabled(callID: call.callID, true)
            self.muteButton?.setTitle("Unmute microphone", for: .normal)
        }
    }
    
    @objc func speakerPressed() {
        guard let call = self.ziwoClient.calls.first else {
            return
        }
        
        if self.ziwoClient.isSpeakerOn(callID: call.callID) {
            self.ziwoClient.setSpeakerEnabled(callID: call.callID, false)
            self.speakerButton?.setTitle("Set speaker ON", for: .normal)
        } else {
            self.ziwoClient.setSpeakerEnabled(callID: call.callID, true)
            self.speakerButton?.setTitle("Set speaker OFF", for: .normal)
        }
    }
    
    @objc func pausePressed() {
        guard let call = self.ziwoClient.calls.first else {
            return
        }
        
        if self.ziwoClient.isPaused(callID: call.callID) {
            self.ziwoClient.setPauseEnabled(callID: call.callID, false)
            self.pauseButton?.setTitle("Hold call", for: .normal)
        } else {
            self.ziwoClient.setPauseEnabled(callID: call.callID, true)
            self.pauseButton?.setTitle("Unhold call", for: .normal)
        }
    }
    
    @objc func callPressed() {
        guard let recipientNumber = self.dialPad?.text else {
            return
        }
        
        self.ziwoClient.call(number: recipientNumber)
        self.handleButtonCall(isCalling: true)
        self.dialPad?.resignFirstResponder()
    }
    
    @objc func answerPressed() {
        guard let call = self.ziwoClient.calls.first else {
            return
        }
        
        self.ziwoClient.answerIncomingCall(callID: call.callID)
        self.handleButtonCall(isCalling: true)
    }
    
    @objc func hangUpPressed() {
        guard let call = self.ziwoClient.calls.first else {
            return
        }
        
        self.ziwoClient.hangUp(callID: call.callID)
    }

}

extension AgentViewController: ZiwoClientDelegate {
    
    // MARK: - Websockets Delegates
    
    func vertoIsConnected() {
        print("[Example App - Ziwo Client] Verto websocket is connected.")
    }
    
    func vertoIsDisconnected() {
        print("[Example App - Ziwo Client] Verto websocket has been disconnected.")
    }
    
    func domainIsConnected() {
        print("[Example App - Ziwo Client] Domain websocket has been disconnected.")
    }
    
    func domainIsDisconnected() {
        print("[Example App - Ziwo Client] Domain websocket has been disconnected.")
    }
    
    // MARK: - Call Delegates
    
    func vertoClientIsReady() {
        print("[Example App - Ziwo Client] Verto client is ready.")
        
        self.ziwoClient.vertoDebug = true
    }
    
    func vertoCallStarted() {
        print("[Example App - Ziwo Client] Call has started.")
        
        self.answerButton?.isHidden = true
        self.pauseButton?.isHidden = false
        self.muteButton?.isHidden = false
        self.speakerButton?.isHidden = false
    }
    
    func vertoReceivedCall(callerID: String) {
        print("[Example App - Ziwo Client] \(callerID) is calling.")
        
        self.answerButton?.isHidden = false
        self.answerButton?.setTitle("Agent n°\(callerID) is calling...", for: .normal)
    }
    
    func vertoCallEnded() {
        print("[Example App - Ziwo Client] Call has ended.")
        
        self.handleButtonCall(isCalling: false)
        self.answerButton?.isHidden = true
        self.pauseButton?.isHidden = true
        self.muteButton?.isHidden = true
        self.speakerButton?.isHidden = true
    }
    
}
