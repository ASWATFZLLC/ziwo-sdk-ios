//
//  Agent.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

public class Agent {
    
    var id: Int = 0
    var email: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var ccPassword: String = ""
    var ccLogin: String = ""
    
    public init(id: Int, email: String, firstName: String, lastName: String, ccPassword: String, ccLogin: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.ccPassword = ccPassword
        self.ccLogin = ccLogin
    }
}
