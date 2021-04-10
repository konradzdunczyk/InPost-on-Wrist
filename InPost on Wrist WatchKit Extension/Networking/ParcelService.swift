//
//  ParcelService.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

protocol ParcelService {
    func getParcels(updatedAfter: Date?, completion: @escaping (Swift.Result<[Parcel], AFError>) -> Void)
}

class NetworkParcelService: ParcelService {
    func getParcels(updatedAfter: Date?, completion: @escaping (Result<[Parcel], AFError>) -> Void) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted({
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

            return $0
        }(DateFormatter()))

        let parameters: Parameters? = {
            guard let updatedAfter = updatedAfter else { return nil }

            let dateFormatter: DateFormatter = {
                $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

                return $0
            }(DateFormatter())

            return [
                "updatedAfter" : dateFormatter.string(from: updatedAfter)
            ]
        }()

        let request = afSession.request("https://api-inmobile-pl.easypack24.net/v1/parcels/tracked",
            method: HTTPMethod.get,
            parameters: parameters,
            headers: inpostCommonHeaders,
            interceptor: authRequestInterceptor)

        request
            .validate()
            .responseDecodable(of: Parcels.self, decoder: decoder) { (response) in
                switch response.result {
                case .success(let parcels):
                    completion(.success(parcels.parcels))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }
}

enum CollectParcelExpectedStatus: String {
    case opened
    case closed
}

protocol CollectParcelService {
    func validateParcel(shipmentNumber: String, openCode: String, location: CLLocation, completion: @escaping (Result<ValidationResponse, AFError>) -> Void)
    func openCompartment(sessionUuid: String, completion: @escaping (Result<OpenedCompartmentInfo, AFError>) -> Void)
    func reopenCompartment(sessionUuid: String, completion: @escaping (Result<OpenedCompartmentInfo, AFError>) -> Void)
    func compartmentStatus(sessionUuid: String, expectedStatus: CollectParcelExpectedStatus, completion: @escaping (Result<OpenedCompartmentStatus, AFError>) -> Void)
    func closeCompartment(sessionUuid: String, completion: @escaping (Result<CloseStatus, AFError>) -> Void)
    func terminate(sessionUuid: String, completion: @escaping (Result<Void, AFError>) -> Void)
}

class NetworkCollectParcelService: CollectParcelService {
    func validateParcel(shipmentNumber: String, openCode: String, location: CLLocation, completion: @escaping (Result<ValidationResponse, AFError>) -> Void) {
        let parameters: [String : Any] = [
            "parcel" : [
                "openCode" : openCode,
                "shipmentNumber" : shipmentNumber
            ],
            "geoPoint" : [
                "longitude" : location.coordinate.longitude,
                "accuracy" : location.horizontalAccuracy,
                "latitude" : location.coordinate.latitude
            ]
        ]

        let request = afSession.request("https://api-inmobile-pl.easypack24.net/v1/collect/validate",
            method: HTTPMethod.post,
            parameters: parameters,
            encoding: JSONEncoding(),
            headers: inpostCommonHeaders,
            interceptor: authRequestInterceptor)

        request
            .validate()
            .responseDecodable(of: ValidationResponse.self) { (response) in
                switch response.result {
                case .success(let result):
                    completion(.success(result))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }

    func openCompartment(sessionUuid: String, completion: @escaping (Result<OpenedCompartmentInfo, AFError>) -> Void) {
        let request = afSession.request("https://api-inmobile-pl.easypack24.net/v1/collect/compartment/open/\(sessionUuid)",
            method: HTTPMethod.post,
            headers: inpostCommonHeaders,
            interceptor: authRequestInterceptor)

        request
            .validate()
            .responseDecodable(of: OpenedCompartmentInfo.self) { (response) in
                switch response.result {
                case .success(let result):
                    completion(.success(result))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }

    func reopenCompartment(sessionUuid: String, completion: @escaping (Result<OpenedCompartmentInfo, AFError>) -> Void) {
        let request = afSession.request("https://api-inmobile-pl.easypack24.net/v1/collect/compartment/reopen/\(sessionUuid)",
            method: HTTPMethod.post,
            headers: inpostCommonHeaders,
            interceptor: authRequestInterceptor)

        request
            .validate()
            .responseDecodable(of: OpenedCompartmentInfo.self) { (response) in
                switch response.result {
                case .success(let result):
                    completion(.success(result))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }

    func compartmentStatus(sessionUuid: String, expectedStatus: CollectParcelExpectedStatus, completion: @escaping (Result<OpenedCompartmentStatus, AFError>) -> Void) {
        let parameters: [String : Any] = ["expected" : expectedStatus.rawValue]

        let request = afSession.request("https://api-inmobile-pl.easypack24.net/v1/collect/compartment/status/\(sessionUuid)",
            method: HTTPMethod.get,
            parameters: parameters,
            headers: inpostCommonHeaders,
            interceptor: authRequestInterceptor)

        request
            .validate()
            .responseDecodable(of: OpenedCompartmentStatus.self) { (response) in
                switch response.result {
                case .success(let result):
                    completion(.success(result))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }

    func closeCompartment(sessionUuid: String, completion: @escaping (Result<CloseStatus, AFError>) -> Void) {
        let request = afSession.request("https://api-inmobile-pl.easypack24.net/v1/collect/compartment/close/\(sessionUuid)",
            method: HTTPMethod.get,
            headers: inpostCommonHeaders,
            interceptor: authRequestInterceptor)

        request
            .validate()
            .responseDecodable(of: CloseStatus.self) { (response) in
                switch response.result {
                case .success(let result):
                    completion(.success(result))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }

    func terminate(sessionUuid: String, completion: @escaping (Result<Void, AFError>) -> Void) {
        let request = afSession.request("https://api-inmobile-pl.easypack24.net/v1/collect/terminate/\(sessionUuid)",
            method: HTTPMethod.post,
            headers: inpostCommonHeaders,
            interceptor: authRequestInterceptor)

        request
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
