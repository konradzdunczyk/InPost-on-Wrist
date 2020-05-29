//
//  AuthInfos.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation

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
