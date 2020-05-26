//
//  LoginController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 26/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import Foundation
import RxRelay
import RxCocoa
import Alamofire

let inpostCommonHeaders: HTTPHeaders = [
    .contentType("application/json"),
    .accept("application/json"),
    .userAgent("InPost-Mobile/2.6.0-release (iOS 13.4.1; iPad5,4; pl)"),
    .acceptLanguage("pl-PL"),
    .acceptEncoding("gzip, deflate, br")
]

struct SmsSentConfirmation: Codable, Equatable {
    let expirationTime: Date // Date | "2020-05-21T00:16:54.749644+02:00"

    enum CodingKeys: String, CodingKey {
        case expirationTime = "expirationTime"
    }
}

struct AuthInfos: Codable, Equatable {
    let refreshToken: String
    let authToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refreshToken"
        case authToken = "authToken"
    }
}

extension AuthInfos {
    var fullAuthToken: String {
        return "Bearer \(authToken)"
    }
}

protocol LoginService {
    func sendSmsCode(to telNumber: String, completion: @escaping (Swift.Result<SmsSentConfirmation, AFError>) -> Void)
    func confirm(telephonNumber: String, with smsCode: String, completion: @escaping (Result<AuthInfos, AFError>) -> Void)
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

        AF.request("https://api-inmobile-pl.easypack24.net/v1/sendSMSCode/\(telNumber)", method: HTTPMethod.get, headers: inpostCommonHeaders)
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
        let request = AF.request("https://api-inmobile-pl.easypack24.net/v1/confirmSMSCode/\(telephonNumber)/\(smsCode)",
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
}

protocol LoginViewModelType {
    var textFieldPlaceholder: String { get }
    var nextButtonName: String { get }

    var rx_loginInfo: BehaviorRelay<String?> { get }

    func newLoginInfoValue(_ value: String?)
    func next()
}

class LoginViewModel: LoginViewModelType {
    var completionHandler: ((String) -> Void)!

    let textFieldPlaceholder: String
    let nextButtonName: String

    let rx_loginInfo = BehaviorRelay<String?>(value: nil)

    init(fieldInitValue: String?, textFieldPlaceholder: String, nextButtonName: String) {
        self.textFieldPlaceholder = textFieldPlaceholder
        self.nextButtonName = nextButtonName

        rx_loginInfo.accept(fieldInitValue)
    }

    func newLoginInfoValue(_ value: String?) {
        guard let value = value else { return }
        print("new value: \(value)")
        rx_loginInfo.accept(value)
    }

    func next() {
        // TODO: Validation
        guard let value = rx_loginInfo.value else { return }
        completionHandler(value)
    }
}

class LoginController: WKInterfaceController {
    @IBOutlet private var tfLoginInfo: WKInterfaceTextField!
    @IBOutlet private var btnNext: WKInterfaceButton!

    private var _viewModel: LoginViewModelType!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let vm = context as? LoginViewModelType else {
            fatalError("Wrong VM type")
        }

        _viewModel = vm
        applyValues()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    private func applyValues() {
        tfLoginInfo.setText(_viewModel.rx_loginInfo.value)
        tfLoginInfo.setPlaceholder(_viewModel.textFieldPlaceholder)

        btnNext.setTitle(_viewModel.nextButtonName)
    }

    @IBAction private func loginInfoValue(_ value: NSString?) {
        let newValue = value as String?
        _viewModel.newLoginInfoValue(newValue)
    }

    @IBAction func nextButtonTap() {
        _viewModel.next()
    }
}
