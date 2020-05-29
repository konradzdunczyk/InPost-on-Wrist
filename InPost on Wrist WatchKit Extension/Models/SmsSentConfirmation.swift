//
//  SmsSentConfirmation.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation

struct SmsSentConfirmation: Codable, Equatable {
    let expirationTime: Date // Date | "2020-05-21T00:16:54.749644+02:00"

    enum CodingKeys: String, CodingKey {
        case expirationTime = "expirationTime"
    }
}
