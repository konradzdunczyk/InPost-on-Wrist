//
//  AppCoordinator.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 26/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import Foundation

protocol UserManagerType {
    var isUserLogedin: Bool { get }

    func login(refreshToken: String, authToken: String)
    func updateAuthToken(_ token: String)
    func logout()
}

class UserManager: UserManagerType {
    private let _authTokensStorage: AuthTokensStorage

    init(authTokensStorage: AuthTokensStorage) {
        self._authTokensStorage = authTokensStorage
    }

    var isUserLogedin: Bool {
        return _authTokensStorage.refreshToken != nil && _authTokensStorage.authToken != nil
    }

    func login(refreshToken: String, authToken: String) {
        _authTokensStorage.saveRefreshToken(refreshToken)
        _authTokensStorage.saveAuthToken(authToken)
    }

    func updateAuthToken(_ token: String) {
        _authTokensStorage.saveAuthToken(token)
    }

    func logout() {
        _authTokensStorage.removeAllData()
    }
}

protocol Coordinator {
    func start()
}

class LoginCoordinator: Coordinator {
    var finishHandler: (() -> Void)?

    private let _userManager: UserManagerType
    private let _loginService: LoginService = NetworkLoginService()

    init(userManager: UserManagerType) {
        self._userManager = userManager
    }

    func start() {
        showPhoneNumberScreen()
    }

    private func showPhoneNumberScreen() {
        let vm = LoginViewModel(fieldInitValue: "504912201", textFieldPlaceholder: "Phone number", nextButtonName: "Next")
        vm.completionHandler = { [weak self] telNumber in
            self?._loginService.sendSmsCode(to: telNumber, completion: { (result) in
                switch result {
                case .success(let confirmation):
                    self?.showSmsCodeScreen(with: telNumber, and: Date())//confirmation.expirationTime)
                case .failure(let error):
                    print(error)
                }
            })
        }

        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "login_loginInfo", context: vm)])
    }

    private func showSmsCodeScreen(with telNumber: String, and expireDate: Date) {
        let vm = LoginViewModel(fieldInitValue: "296843", textFieldPlaceholder: "SMS Code", nextButtonName: "Login")
        vm.completionHandler = { [weak self] smsCode in
            self?._loginService.confirm(telephonNumber: telNumber, with: smsCode, completion: { (result) in
                switch result {
                case .success(let authInfo):
                    self?.finish(with: authInfo)
                case .failure(let error):
                    print(error)
                }
            })
        }

        WKExtension.shared().rootInterfaceController?.pushController(withName: "login_loginInfo", context: vm)
    }

    private func finish(with authInfo: AuthInfos) {
        _userManager.login(refreshToken: authInfo.refreshToken, authToken: authInfo.fullAuthToken)
        finishHandler?()
    }
}

class AppCoordinator: Coordinator {
    let userManager: UserManagerType = UserManager(authTokensStorage: AuthTokensKeychainStorage())
    lazy var loginCoordinator = LoginCoordinator(userManager: userManager)

    func start() {
        if userManager.isUserLogedin {
            afterLogin()
        } else {
            loginCoordinator.start()
            loginCoordinator.finishHandler = { [weak self] in
                self?.afterLogin()
            }
        }
    }

    func afterLogin() {
        fatalError("Not implemented")
    }
}
