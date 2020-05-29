//
//  Parcel.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation

// MARK: - Parcel
struct Parcel: Codable, Equatable {
    let shipmentNumber: String
    let shipmentType: String
    let status: String
    let statusHistory: [StatusHistory]
    let isObserved: Bool
    let expiryDate: Date?
    let pickupDate: Date?
    let openCode: String?
    let phoneNumber: String
    let qrCode: String?
    let pickupPoint: PickupPoint
    let senderName: String
    let storedDate: Date?
    let isMobileCollectPossible: Bool

    enum CodingKeys: String, CodingKey {
        case shipmentNumber = "shipmentNumber"
        case shipmentType = "shipmentType"
        case status = "status"
        case statusHistory = "statusHistory"
        case isObserved = "isObserved"
        case expiryDate = "expiryDate"
        case pickupDate = "pickupDate"
        case pickupPoint = "pickupPoint"
        case openCode = "openCode"
        case phoneNumber = "phoneNumber"
        case qrCode = "qrCode"
        case senderName = "senderName"
        case storedDate = "storedDate"
        case isMobileCollectPossible = "isMobileCollectPossible"
    }
}

// MARK: - PickupPoint
struct PickupPoint: Codable, Equatable {
    let name: String
    let status: String
    let location: Location
    let locationDescription: String?
    let addressDetails: AddressDetails?
    let virtual: Int
    let type: [String]

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case status = "status"
        case location = "location"
        case locationDescription = "locationDescription"
        case addressDetails = "addressDetails"
        case virtual = "virtual"
        case type = "type"
    }
}

// MARK: - AddressDetails
struct AddressDetails: Codable, Equatable {
    let city: String
    let province: String
    let postCode: String
    let street: String
    let buildingNumber: String

    enum CodingKeys: String, CodingKey {
        case city = "city"
        case province = "province"
        case postCode = "postCode"
        case street = "street"
        case buildingNumber = "buildingNumber"
    }
}

// MARK: - Location
struct Location: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case latitude = "latitude"
        case longitude = "longitude"
    }
}

// MARK: - StatusHistory
struct StatusHistory: Codable, Equatable {
    let status: String
    let date: Date

    enum CodingKeys: String, CodingKey {
        case status = "status"
        case date = "date"
    }
}
