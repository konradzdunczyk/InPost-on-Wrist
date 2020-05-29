//
//  Networking.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation
import Alamofire

final class RequestInterceptor: Alamofire.RequestInterceptor {
    private let storage: AuthTokensStorage
    private let loginService: LoginService

    init(storage: AuthTokensStorage, loginService: LoginService) {
        self.storage = storage
        self.loginService = loginService
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
//        guard urlRequest.url?.absoluteString.hasPrefix("https://api.authenticated.com") == true else {
//            /// If the request does not require authentication, we can directly return it as unmodified.
//            return completion(.success(urlRequest))
//        }
        var urlRequest = urlRequest

        /// Set the Authorization header value using the access token.
        urlRequest.setValue(storage.authToken, forHTTPHeaderField: "Authorization")

        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401,
            let refreshToken = storage.refreshToken, let authToken = storage.authToken else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetryWithError(error))
        }

        loginService.refreshAuthToken(with: refreshToken, oldAuthToken: authToken) { [weak self] (result) in
            guard let self = self else { return }

            switch result {
            case .success(let token):
                self.storage.saveAuthToken(token)
                completion(.retry)
            case .failure(let error):
                completion(.doNotRetryWithError(error))
            }
        }
    }
}

let inpostCommonHeaders: HTTPHeaders = [
    .contentType("application/json"),
    .accept("application/json"),
    .userAgent("InPost-Mobile/2.6.0-release (iOS 13.4.1; iPad5,4; pl)"),
    .acceptLanguage("pl-PL"),
    .acceptEncoding("gzip, deflate, br")
]

let authRequestInterceptor = RequestInterceptor(storage: AuthTokensKeychainStorage(), loginService: NetworkLoginService())
