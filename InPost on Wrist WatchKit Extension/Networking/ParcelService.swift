//
//  ParcelService.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import Foundation
import Alamofire

protocol ParcelService {
    func getParcels(updatedAfter: Date?, completion: @escaping (Swift.Result<[Parcel], AFError>) -> Void)
}

class NetworkParcelService: ParcelService {
    func getParcels(updatedAfter: Date?, completion: @escaping (Result<[Parcel], AFError>) -> Void) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let request = AF.request("https://api-inmobile-pl.easypack24.net/v1/parcel/",
            method: HTTPMethod.get,
            headers: inpostCommonHeaders,
            interceptor: authRequestInterceptor)

        request
            .validate()
            .responseDecodable(of: [Parcel].self, decoder: decoder) { (response) in
                switch response.result {
                case .success(let parcels):
                    completion(.success(parcels))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }
}
