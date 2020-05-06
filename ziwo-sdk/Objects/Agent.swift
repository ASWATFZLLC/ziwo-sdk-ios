//
//  Agent.swift
//  ziwo-sdk
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation

/**
 Represent call-center Agent.
 */
public class Agent {
    
    /// Agent's ID
    var id: Int = 0
    /// Agent's email
    var email: String = ""
    /// Agent's first name
    var firstName: String = ""
    /// Agent's last name
    var lastName: String = ""
    /// Agent's ccPassword
    var ccPassword: String = ""
    /// Agent's ccLogin
    var ccLogin: String = ""
    
    /**
    Initializes a new agent according to given informations.

    - Parameters:
       - id: ID of the agent.
       - email: Email with which the agent is registered on his Ziwo Domain.
       - firstName: Firstname of the agent.
       - lastName: Lastname of the agent.
       - ccPassword: ccPassword for the agent login on call center.
       - ccLogin: Login id for the call center platform.

    - Returns: A well-formated Ziwo Agent.
    */
    public init(id: Int, email: String, firstName: String, lastName: String, ccPassword: String, ccLogin: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.ccPassword = ccPassword
        self.ccLogin = ccLogin
    }
}
