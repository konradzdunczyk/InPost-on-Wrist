//
//  Parcel.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation

struct Parcels: Codable, Equatable {
    let parcels: [Parcel]

    enum CodingKeys: String, CodingKey {
        case parcels = "parcels"
    }
}

// MARK: - Parcel
struct Parcel: Codable, Equatable {
    let shipmentNumber: String
    let shipmentType: String
    let status: String
//    let statusHistory: [StatusHistory]?
    let openCode: String?
    let qrCode: String?
    let expiryDate: Date?
//    let storedDate: Date?
//    let parcelSize: String?
    let receiver: Receiver?
    let sender: Sender?
    let pickUpPoint: PickUpPoint?
    let multiCompartment: MultiCompartment?
//    let observed: Bool
//    let endOfWeekCollection: Bool
//    let operations: Operations?

    enum CodingKeys: String, CodingKey {
        case shipmentNumber = "shipmentNumber"
        case shipmentType = "shipmentType"
        case status = "status"
//        case statusHistory = "statusHistory"
        case openCode = "openCode"
        case qrCode = "qrCode"
        case expiryDate = "expiryDate"
//        case storedDate = "storedDate"
//        case parcelSize = "parcelSize"
        case receiver = "receiver"
        case sender = "sender"
        case pickUpPoint = "pickUpPoint"
        case multiCompartment = "multiCompartment"
//        case observed = "observed"
//        case endOfWeekCollection = "endOfWeekCollection"
//        case operations = "operations"
    }
}

// MARK: - PickupPoint
struct PickUpPoint: Codable, Equatable {
    let name: String
    let location: Location
    let locationDescription: String
    let openingHours: String
    let addressDetails: AddressDetails?
    let virtual: Int
    let type: [String]
    let location247: Bool
    let doubled: Bool
    let imageURL: String

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case location = "location"
        case locationDescription = "locationDescription"
        case openingHours = "openingHours"
        case addressDetails = "addressDetails"
        case virtual = "virtual"
        case type = "type"
        case location247 = "location247"
        case doubled = "doubled"
        case imageURL = "imageUrl"
    }
}

// MARK: - AddressDetails
struct AddressDetails: Codable, Equatable {
    let postCode: String
    let city: String
    let province: String
    let street: String
    let buildingNumber: String

    enum CodingKeys: String, CodingKey {
        case postCode = "postCode"
        case city = "city"
        case province = "province"
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

// MARK: - MultiCompartment
struct MultiCompartment: Codable, Equatable {
    let uuid: String
    let shipmentNumbers: [String]?
    let presentation: Bool
    let collected: Bool

    enum CodingKeys: String, CodingKey {
        case uuid = "uuid"
        case shipmentNumbers = "shipmentNumbers"
        case presentation = "presentation"
        case collected = "collected"
    }
}

struct Operations: Codable, Equatable {
    let manualArchive: Bool
    let delete: Bool
    let collect: Bool

    enum CodingKeys: String, CodingKey {
        case manualArchive = "manualArchive"
        case delete = "delete"
        case collect = "collect"
    }
}

// MARK: - Receiver
struct Receiver: Codable, Equatable {
    let email: String
    let phoneNumber: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case email = "email"
        case phoneNumber = "phoneNumber"
        case name = "name"
    }
}

// MARK: - Sender
struct Sender: Codable, Equatable {
    let name: String

    enum CodingKeys: String, CodingKey {
        case name = "name"
    }
}
