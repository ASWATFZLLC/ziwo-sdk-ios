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
                self.ziwoClient.domainDebug = false
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
    
    @objc func callPressed() {
        guard let recipientNumber = self.dialPad?.text else {
            return
        }
        
        self.ziwoClient.call(number: recipientNumber)
        self.handleButtonCall(isCalling: true)
    }
    
    @objc func hangUpPressed() {
        self.ziwoClient.hangUp()
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
        self.ziwoClient.domainDebug = false
    }
    
    func vertoCallStarted() {
        print("[Example App - Ziwo Client] Call has started.")
    }
    
    func vertoCallEnded() {
        print("[Example App - Ziwo Client] Call has ended.")
        
        self.handleButtonCall(isCalling: false)
    }
    
}
