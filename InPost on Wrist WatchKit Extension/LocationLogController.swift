//
//  LocationLogController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 28/06/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import CoreLocation
import RxSwift
import RxCoreLocation

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

    var collectParcelService: CollectParcelService!

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
            // ERROR
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
            // ERROR
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

    func terminate() {
        guard case CollectStatus.inProgress(compartmentStatus: .closed(initiali: false)) = collectStatus else {
            // ERROR
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

class LocationLogController: WKInterfaceController {
    @IBOutlet var lblLog: WKInterfaceLabel!

    private let _locationManager = CLLocationManager()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        _locationManager.delegate = self
    }

    override func didAppear() {
        super.didAppear()

        _locationManager.requestWhenInUseAuthorization()
//        _locationManager.startUpdatingLocation()
    }

    private func updateLog() {
        let locations: String = {
            guard let location = _locationManager.location else { return "none" }

            return """
            coor: \(location.coordinate)
            horAccu: \(location.horizontalAccuracy)
            """
        }()

        let log = """
        location:
            \(locations)
        """

        lblLog.setText(log)
    }

    private func showError(_ error: Error) {
        let log = "Error: \(error)"
        lblLog.setText(log)
    }

    private func showAuthStatus(_ status: CLAuthorizationStatus) {
        let log = "Status: \(status.rawValue)"
        lblLog.setText(log)
    }
}

extension LocationLogController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateLog()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        updateLog()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showError(error)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        showAuthStatus(status)
    }
}
