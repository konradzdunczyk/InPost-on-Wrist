//
//  LoginService.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation
import Alamofire

protocol LoginService {
    func sendSmsCode(to telNumber: String, completion: @escaping (Swift.Result<SmsSentConfirmation, AFError>) -> Void)
    func confirm(telephonNumber: String, with smsCode: String, completion: @escaping (Result<AuthInfos, AFError>) -> Void)
    func refreshAuthToken(with refreshToken: String, oldAuthToken: String, completion: @escaping (Result<String, AFError>) -> Void)
}

class NetworkLoginService: LoginService {
    func sendSmsCode(to telNumber: String, completion: @escaping (Result<SmsSentConfirmation, AFError>) -> Void) {
//        GET /v1/sendSMSCode/504912201 HTTP/1.1
//        Host: api-inmobile-pl.easypack24.net
//        Content-Type: application/json
//        Accept: application/json
//        User-Agent: InPost-Mobile/2.6.0-release (iOS 13.4.1; iPad5,4; pl)
//        Accept-Language: pl-PL
//        Accept-Encoding: gzip, deflate, br
//        Connection: keep-alive

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted({
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"

            return $0
        }(DateFormatter()))

        afSession.request("https://api-inmobile-pl.easypack24.net/v1/sendSMSCode/\(telNumber)", method: HTTPMethod.get, headers: inpostCommonHeaders)
            .validate()
            .responseDecodable(of: SmsSentConfirmation.self, decoder: decoder) { (response) in
                switch response.result {
                case .success(let model):
                    completion(.success(model))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    func confirm(telephonNumber: String, with smsCode: String, completion: @escaping (Result<AuthInfos, AFError>) -> Void) {
//        POST /v1/confirmSMSCode/504912201/663999 HTTP/1.1
//        Host    api-inmobile-pl.easypack24.net
//        Content-Type    application/json
//        Connection    keep-alive
//        Accept    application/json
//        User-Agent    InPost-Mobile/2.6.0-release (iOS 13.4.1; iPad5,4; pl)
//        Accept-Language    pl-PL
//        Content-Length    19
//        Accept-Encoding    gzip, deflate, br

        // BODY
        // {"phoneOS":"Apple"}

        let parameters: [String : String] = ["phoneOS" : "Apple"]
        let request = afSession.request("https://api-inmobile-pl.easypack24.net/v1/confirmSMSCode/\(telephonNumber)/\(smsCode)",
            method: HTTPMethod.post,
            parameters: parameters,
            encoder: JSONParameterEncoder.default,
            headers: inpostCommonHeaders)

        request
            .validate()
            .responseDecodable(of: AuthInfos.self) { (response) in
                switch response.result {
                case .success(let model):
                    completion(.success(model))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }

    func refreshAuthToken(with refreshToken: String, oldAuthToken: String, completion: @escaping (Result<String, AFError>) -> Void) {
//        POST /v1/authenticate HTTP/1.1
//        Host    api-inmobile-pl.easypack24.net
//        Content-Type    application/json
//        Accept-Encoding    gzip, deflate, br
//        Connection    keep-alive
//        Accept    application/json
//        User-Agent    InPost-Mobile/2.6.0-release (iOS 13.5; iPhone11,2; pl)
//        Authorization    Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
//        Accept-Language    pl-PL
//        Content-Length    73

        // BODY
//        {"refreshToken":"90f5dfb7-a816-4101-9a95-5962dff45908","phoneOS":"Apple"}

        let parameters: [String : String] = [
            "refreshToken" : refreshToken,
            "phoneOS" : "Apple"
        ]

        var headers = inpostCommonHeaders
        headers.add(.authorization(oldAuthToken))

        let request = afSession.request("https://api-inmobile-pl.easypack24.net/v1/authenticate",
            method: HTTPMethod.post,
            parameters: parameters,
            encoder: JSONParameterEncoder.default,
            headers: headers)

        request
            .validate()
            .responseJSON { (response) in
                switch response.result {
                case .success(let json):
                    guard let jsonObject = json as? [String : Any],
                        let authToken = jsonObject["authToken"] as? String else {
                            let error = AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: NSError()))
                            completion(.failure(error))
                            return
                    }
                    completion(.success(authToken))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
