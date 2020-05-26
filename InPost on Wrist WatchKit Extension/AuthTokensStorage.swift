//
//  AuthTokensStorage.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 26/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation
import KeychainAccess

protocol AuthTokensStorageReadOnly {
    var refreshToken: String? { get }
    var authToken: String? { get }
}

protocol AuthTokensStorage: AuthTokensStorageReadOnly {
    func saveRefreshToken(_ token: String)
    func saveAuthToken(_ token: String)
    func removeAllData()
}

class AuthTokensKeychainStorage: AuthTokensStorage {
    private let _keychain = Keychain(service: "pl.kondziu.inpostOnWrist")
        .synchronizable(false)
        .accessibility(.whenUnlockedThisDeviceOnly)

    var refreshToken: String? {
        try? _keychain.get("refreshToken")
    }
    var authToken: String? {
        try? _keychain.get("authToken")
    }

    func saveRefreshToken(_ token: String) {
        _keychain[string: "refreshToken"] = token
    }

    func saveAuthToken(_ token: String) {
        _keychain[string: "authToken"] = token
    }

    func removeAllData() {
        do {
            try _keychain.removeAll()
        } catch {
            print("Error: \(error)")
        }
    }
}
