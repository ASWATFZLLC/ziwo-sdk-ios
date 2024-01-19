//
//  Network.swift
//  ZiwoExampleApp
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import SwiftyJSON
import ziwo_sdk

struct Network {

    struct NetworkError {
        
        // API
        static let invalidLogin: NSError = NSError(domain: "", code: 401, userInfo: ["reason": "Invalid credentials, please try again."])
        static let unauthorized: NSError = NSError(domain: "", code: 403, userInfo: ["reason": "Your token has espired. Please try to relog."])
        static let domainError: NSError = NSError(domain: "", code: 404, userInfo: ["reason": "The domain you entered does not exist."])
        static let internalServerError: NSError = NSError(domain: "", code: 500, userInfo: ["reason": "Oops, something went wrong. (Internal server error : 500)"])
        
        // In-App
        static let invalidString: NSError = NSError(domain: "", code: 0, userInfo: ["reason": "Invalid String Response"])
    }

    struct StatusCode {
        static let INVALID_CREDENTIALS: Int = 401
        static let UNAUTHORIZED: Int = 403
        static let DOMAIN_ERROR: Int = 404
        static let SERVER_ERROR: Int = 500
    }
    
    static func login(email: String, password: String, remember: Bool) -> Promise<String> {
        return Promise { seal in
            guard let domain = ZiwoSDK.shared.domain else {
                return seal.reject(NetworkError.unauthorized)
            }
            
            let params: Parameters = [
                "username": email,
                "password": password,
                "remember": remember
            ]
            
            debugPrint("-----> \("https://\(domain)-api.aswat.co/auth/login")")
            AF.request(URL(string: "https://\(domain)-api.aswat.co/auth/login")!, method: .post, parameters: params, encoding: URLEncoding.default, headers: [:]).responseJSON { (result) in
                
                Network.handleStatusCode(response: result.response) { error in
                    seal.reject(error)
                }
                
                guard let stringResponse = result.value else {
                    return seal.reject(NetworkError.invalidString)
                }
                
                let jsonResponse = JSON(stringResponse)
                
                seal.fulfill(jsonResponse["content"]["access_token"].stringValue)
            }
        }
    }
    
    static func autoLogin() -> Promise<Void> {
        return Promise { seal in
            guard let domain = ZiwoSDK.shared.domain,
                let accessToken = ZiwoSDK.shared.accessToken else {
                    return seal.reject(NetworkError.unauthorized)
            }
            
            let headers: HTTPHeaders = [
                "access_token": accessToken
            ]
            
            debugPrint("-----> \("https://\(domain)-api.aswat.co/agents/autoLogin")")
            AF.request(URL(string: "https://\(domain)-api.aswat.co/agents/autoLogin")!, method: .put, parameters: [:], encoding: URLEncoding.default, headers: headers).responseJSON { (result) in
                
                if let error = result.error {
                    seal.reject(error)
                }
                
                Network.handleStatusCode(response: result.response) { error in
                    seal.reject(error)
                }
                
                seal.fulfill(())
            }
        }
    }
    
    static func getProfile() -> Promise<Agent> {
        return Promise { seal in
            guard let domain = ZiwoSDK.shared.domain,
                let accessToken = ZiwoSDK.shared.accessToken else {
                    return seal.reject(NetworkError.unauthorized)
            }

            let headers: HTTPHeaders = [
                "access_token": accessToken
            ]

            debugPrint("-----> \("https://\(domain)-api.aswat.co/profile")")
            AF.request(URL(string: "https://\(domain)-api.aswat.co/profile")!, method: .get, parameters: [:], encoding: URLEncoding.default, headers: headers).responseJSON { (result) in

                Network.handleStatusCode(response: result.response) { error in
                    seal.reject(error)
                }

                guard let stringResponse = result.value else {
                    return seal.reject(NetworkError.invalidString)
                }

                let jsonResponse = JSON(stringResponse)

                seal.fulfill(
                    Agent(id: jsonResponse["content"]["id"].intValue,
                          email: jsonResponse["content"]["username"].stringValue,
                          firstName: jsonResponse["content"]["firstName"].stringValue,
                          lastName: jsonResponse["content"]["lastName"].stringValue,
                          ccPassword: jsonResponse["content"]["ccPassword"].stringValue,
                          ccLogin: jsonResponse["content"]["ccLogin"].stringValue
                    )
                )
            }
        }
    }

    // MARK: - Generic HTTP Methods
    
    static func handleStatusCode(response: HTTPURLResponse?, completion: @escaping (Error) -> ()) -> Void {
        if let statusCode = response?.statusCode {
            if statusCode == StatusCode.INVALID_CREDENTIALS {
                completion(NetworkError.invalidLogin)
            } else if statusCode == StatusCode.UNAUTHORIZED {
                completion(NetworkError.unauthorized)
            }  else if statusCode == StatusCode.SERVER_ERROR {
                completion(NetworkError.internalServerError)
            } else if statusCode == StatusCode.DOMAIN_ERROR {
                completion(NetworkError.domainError)
            } else if statusCode != 200 {
                completion(NetworkError.internalServerError)
            }
        }
    }
    
}
