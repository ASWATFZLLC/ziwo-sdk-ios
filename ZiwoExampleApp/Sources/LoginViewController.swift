//
//  LoginViewController.swift
//  ZiwoExampleApp
//
//  Created by Emilien ROUSSEL on 22/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import UIKit
import ZiwoSDK

class LoginViewController: UIViewController {
    
    // MARK: - UI Elements
    
    var domainTextField: UITextField?
    var emailTextField: UITextField?
    var passwordTextField: UITextField?
    var loginButton: UIButton?
    
    // MARK: - Basic VC Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.setupUI()
    }
    
    // MARK: - UI Methods
    
    func setupUI() {
        self.view.backgroundColor = .lightGray
        
        let fieldSize = self.view.frame.width - 40
        let suffix: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: fieldSize / 2, height: 30))
        suffix.textColor = .darkGray
        suffix.text = ".aswat.co"
        
        self.domainTextField = UITextField(frame: CGRect(x: 20, y: Frame.at(percent: 10, of: .Height, ofView: self.view),
                                                         width: self.view.frame.width - 40, height: 30))
        self.domainTextField?.backgroundColor = .white
        self.domainTextField?.placeholder = "your-domain"
        self.domainTextField?.textAlignment = .center
        self.domainTextField?.returnKeyType = .done
        self.domainTextField?.autocorrectionType = .no
        self.domainTextField?.autocapitalizationType = .none
        self.domainTextField?.rightView = suffix
        self.domainTextField?.rightViewMode = .always
        self.view.addSubview(self.domainTextField!)
        
        self.emailTextField = UITextField(frame: CGRect(x: 20, y: Frame.below(view: self.domainTextField, withOffset: 10),
                                                        width: self.view.frame.width - 40, height: 30))
        self.emailTextField?.autocorrectionType = .no
        self.emailTextField?.autocapitalizationType = .none
        self.emailTextField?.keyboardType = .emailAddress
        self.emailTextField?.backgroundColor = .white
        self.emailTextField?.textAlignment = .center
        self.emailTextField?.placeholder = "agent-email@domain.com"
        self.view.addSubview(self.emailTextField!)
        
        self.passwordTextField = UITextField(frame: CGRect(x: 20, y: Frame.below(view: self.emailTextField, withOffset: 10),
                                                           width: self.view.frame.width - 40, height: 30))
        self.passwordTextField?.autocorrectionType = .no
        self.passwordTextField?.autocapitalizationType = .none
        self.passwordTextField?.backgroundColor = .white
        self.passwordTextField?.textAlignment = .center
        self.passwordTextField?.placeholder = "Agent password"
        self.passwordTextField?.isSecureTextEntry = true
        self.view.addSubview(self.passwordTextField!)
        
        self.loginButton = UIButton(frame: CGRect(x: 20, y: Frame.below(view: self.passwordTextField, withOffset: 20),
                                                  width: self.view.frame.width - 40, height: 30))
        self.loginButton?.addTarget(self, action: #selector(self.loginButtonPressed), for: .touchUpInside)
        self.loginButton?.backgroundColor = .blue
        self.loginButton?.titleLabel?.tintColor = .white
        self.loginButton?.setTitle("Authenticate", for: .normal)
        self.view.addSubview(self.loginButton!)
    }
    
    public func redirectLoggedAgent(animated: Bool = false) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "AgentNavigationController")
        vc.modalPresentationStyle = .fullScreen
        vc.modalPresentationCapturesStatusBarAppearance = true
        
        self.present(vc, animated: animated)
    }
    
    // MARK: - OBJC Methods
    
    @objc func loginButtonPressed() {
        guard let domain = self.domainTextField?.text, let email = self.emailTextField?.text,
            let password = self.passwordTextField?.text else {
                return
        }
        
        // NOTE: - First, initialize the domain in order to let the SDK request on the correct API / Websocket.
        ZiwoSDK.shared.domain = domain
        
        /**
         The Ziwo authentication works this way : first you login the agent, then you authenticate him with the autologin (`.GET /agents/autoLogin`).
         After those two steps, you can fetch the profile of the agent with the access_token that `.GET /auth/login` returns.
         */
        Network.login(email: email, password: password, remember: false).done { accessToken in
            
            // NOTE: - At that point you should get an access token, set it so the SDK can connect the domain websocket later.
            ZiwoSDK.shared.accessToken = accessToken
            
            self.redirectLoggedAgent()
        }.catch { error in
            print("[Example App Login] - Error while trying to login agent : \(error.localizedDescription)")
        }
    }

}

