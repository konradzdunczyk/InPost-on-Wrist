//
//  ParcelCollectManager.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 21/03/2021.
//  Copyright © 2021 Konrad Zdunczyk. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire

class MockCollectParcelService: CollectParcelService {
    private var _statusCount = 0

    private let _compratment = Compartment(name: "6L4",
                                           location: .init(side: "L",
                                                           column: "6",
                                                           row: "4"))

    func validateParcel(shipmentNumber: String, openCode: String, location: CLLocation, completion: @escaping (Result<ValidationResponse, AFError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(ValidationResponse(sessionUUID: UUID().uuidString, sessionExpirationTime: 10000)))
        }
    }

    func openCompartment(sessionUuid: String, completion: @escaping (Result<OpenedCompartmentInfo, AFError>) -> Void) {
        _statusCount = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self._statusCount = 0
            completion(.success(OpenedCompartmentInfo(compartment: self._compratment,
                                                      openCompartmentWaitingTime: 37000,
                                                      actionTime: 60000,
                                                      confirmActionTime: 60000)))
        }
    }

    func reopenCompartment(sessionUuid: String, completion: @escaping (Result<OpenedCompartmentInfo, AFError>) -> Void) {
        _statusCount = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self._statusCount = 0
            completion(.success(OpenedCompartmentInfo(compartment: self._compratment,
                                                      openCompartmentWaitingTime: 37000,
                                                      actionTime: 60000,
                                                      confirmActionTime: 60000)))
        }
    }

    func compartmentStatus(sessionUuid: String, expectedStatus: CollectParcelExpectedStatus, completion: @escaping (Result<OpenedCompartmentStatus, AFError>) -> Void) {
        _statusCount += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self._statusCount > 3 {
                let compartment: Compartment? = expectedStatus == .opened ? self._compratment : nil

                completion(.success(OpenedCompartmentStatus(compartment: compartment, status: expectedStatus.rawValue)))
            } else {
                if self._statusCount == 2 {
                    completion(.failure(AFError.explicitlyCancelled))
                    return
                }

                let status: CollectParcelExpectedStatus = expectedStatus == .opened ? .closed : .opened
                let compartment: Compartment? = status == .opened ? self._compratment : nil

                completion(.success(OpenedCompartmentStatus(compartment: compartment, status: status.rawValue)))
            }
        }
    }

    func closeCompartment(sessionUuid: String, completion: @escaping (Result<CloseStatus, AFError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(.init(closed: true)))
        }
    }

    func terminate(sessionUuid: String, completion: @escaping (Result<Void, AFError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(()))
        }
    }
}

protocol ParcelCollectManagerDelegate: class {
    func parcelColectManager(_ manager: ParcelCollectManager, didChangeStatus status: ParcelCollectManager.CollectStatus)
    func parcelColectManager(_ manager: ParcelCollectManager, gotError error: Error)
}

class ParcelCollectManager {
    enum CollectStatus: Equatable {
        case prepared
        case validating
        case validated
        case inProgress(compartmentStatus: CompartmentStatus)
        case terminating
        case terminated
    }

    enum CompartmentStatus: Equatable {
        case opened(reopened: Bool, compartment: Compartment)
        case closed(initiali: Bool)
    }

    var collectParcelService: CollectParcelService = NetworkCollectParcelService()
//    var collectParcelService: CollectParcelService = MockCollectParcelService()

    weak var delegate: ParcelCollectManagerDelegate? {
        didSet {
            guard let delegate = delegate else { return }
            if let oldValue = oldValue, oldValue === delegate { return }

            delegate.parcelColectManager(self, didChangeStatus: collectStatus)
        }
    }

    private(set) var collectStatus: CollectStatus = .prepared {
        didSet {
            guard oldValue != collectStatus else { return }

            delegate?.parcelColectManager(self, didChangeStatus: collectStatus)
        }
    }

    private let _shipmentNumber: String
    private let _openCode: String

    private var _validationResponse: ValidationResponse?

    private var _sessionUuid: String {
        return _validationResponse?.sessionUUID ?? ""
    }

    private let _maxStatusCheckAttempt: Int = 3

    init(shipmentNumber: String, openCode: String) {
        self._shipmentNumber = shipmentNumber
        self._openCode = openCode
    }

    func start(location: CLLocation) {
        guard collectStatus == .prepared else {
            log.error("collectStatus != .prepared")
            return
        }

        collectStatus = .validating

        collectParcelService
            .validateParcel(shipmentNumber: _shipmentNumber,
                            openCode: _openCode,
                            location: location) { [weak self] (result) in
                                switch result {
                                case .success(let validationResponse):
                                    self?._validationResponse = validationResponse
                                    self?.collectStatus = .validated
                                case .failure(let error):
                                    self?.collectStatus = .prepared
                                    self?.delegate?.parcelColectManager(self!, gotError: error)
                                }
        }
    }

    func openCompartment() {
        guard collectStatus == .validated else {
            log.error("collectStatus != .validated")
            return
        }

        collectStatus = .inProgress(compartmentStatus: .closed(initiali: true))

        collectParcelService.openCompartment(sessionUuid: _sessionUuid) { [weak self] (result) in
            switch result {
            case .success(let info):
                self?.collectStatus = .inProgress(compartmentStatus: .opened(reopened: false, compartment: info.compartment))
                self?.startCheckingStatus()
            case .failure(let error):
                self?.collectStatus = .validated
                self?.delegate?.parcelColectManager(self!, gotError: error)
            }
        }
    }

    func reopenCompartment() {
        guard collectStatus == .inProgress(compartmentStatus: .closed(initiali: false)) else {
            log.error("collectStatus != .closed(initiali: false)")
            return
        }

        collectStatus = .inProgress(compartmentStatus: .closed(initiali: true))

        collectParcelService.reopenCompartment(sessionUuid: _sessionUuid) { [weak self] (result) in
            switch result {
            case .success(let info):
                self?.collectStatus = .inProgress(compartmentStatus: .opened(reopened: true, compartment: info.compartment))
                self?.startCheckingStatus()
            case .failure(let error):
                self?.collectStatus = .inProgress(compartmentStatus: .closed(initiali: true))
                self?.delegate?.parcelColectManager(self!, gotError: error)
            }
        }
    }

    func terminate() {
        guard case CollectStatus.inProgress(compartmentStatus: .closed(initiali: false)) = collectStatus else {
            log.error("collectStatus != .inProgress")
            return
        }

        collectStatus = .terminating

        collectParcelService.terminate(sessionUuid: _sessionUuid) { [weak self] (result) in
            switch result {
            case .success:
                self?.collectStatus = .terminated
            case .failure(let error):
                self?.collectStatus = .inProgress(compartmentStatus: .closed(initiali: false))
                self?.delegate?.parcelColectManager(self!, gotError: error)
            }
        }
    }

    private func startCheckingStatus() {
        let errorHandler: (Error) -> Void = { [weak self] error in
            self?.delegate?.parcelColectManager(self!, gotError: error)
        }

        waitFor(expectedStatus: .opened) { [weak self, _sessionUuid] (result) in
            switch result {
            case .success(_):
                self?.waitFor(expectedStatus: .closed) { (result) in
                    switch result {
                    case .success(_):
                        self?.collectParcelService.closeCompartment(sessionUuid: _sessionUuid) { (result) in
                            switch result {
                            case .success:
                                self?.collectStatus = .inProgress(compartmentStatus: .closed(initiali: false))
                            case .failure(let error):
                                errorHandler(error)
                            }
                        }
                    case .failure(let error):
                        errorHandler(error)
                    }
                }
            case .failure(let error):
                errorHandler(error)
            }
        }
    }

    private func waitFor(expectedStatus: CollectParcelExpectedStatus, attempt: Int = 0, completion: @escaping (Result<OpenedCompartmentStatus, Error>) -> Void) {
        collectParcelService.compartmentStatus(sessionUuid: _sessionUuid, expectedStatus: expectedStatus) { [weak self, _maxStatusCheckAttempt] (result) in
            switch result {
            case .success(let status):
                let newStatus = CollectParcelExpectedStatus(rawValue: status.status.lowercased())
                if newStatus == expectedStatus {
                    completion(.success(status))
                } else {
                    self?.waitFor(expectedStatus: expectedStatus, completion: completion)
                }
            case .failure(let error):
                if attempt >= _maxStatusCheckAttempt {
                    completion(.failure(error))
                } else {
                    self?.waitFor(expectedStatus: expectedStatus, attempt: attempt + 1, completion: completion)
                }
            }
        }
    }
}
