//
//  CollectParcel.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 28/06/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation

struct ValidationResponse: Codable, Equatable {
    let sessionUUID: String
    let sessionExpirationTime: Int

    enum CodingKeys: String, CodingKey {
        case sessionUUID = "sessionUuid"
        case sessionExpirationTime = "sessionExpirationTime"
    }
}

//======================

struct OpenedCompartmentInfo: Codable, Equatable {
    let compartment: Compartment
    let openCompartmentWaitingTime: Int
    let actionTime: Int
    let confirmActionTime: Int

    enum CodingKeys: String, CodingKey {
        case compartment = "compartment"
        case openCompartmentWaitingTime = "openCompartmentWaitingTime"
        case actionTime = "actionTime"
        case confirmActionTime = "confirmActionTime"
    }
}

// MARK: - Compartment
struct Compartment: Codable, Equatable {
    let name: String
    let location: CompartmentLocation

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case location = "location"
    }
}

// MARK: - CompartmentLocation
struct CompartmentLocation: Codable, Equatable {
    let side: String
    let column: String
    let row: String

    enum CodingKeys: String, CodingKey {
        case side = "side"
        case column = "column"
        case row = "row"
    }
}

//===============================

struct OpenedCompartmentStatus: Codable, Equatable {
    let compartment: Compartment?
    let status: String

    enum CodingKeys: String, CodingKey {
        case compartment = "compartment"
        case status = "status"
    }
}

//==================================

struct CloseStatus: Codable, Equatable {
    let closed: Bool

    enum CodingKeys: String, CodingKey {
        case closed = "closed"
    }
}
