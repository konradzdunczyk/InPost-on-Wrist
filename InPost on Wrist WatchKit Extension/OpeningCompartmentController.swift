//
//  OpeningCompartmentController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 21/03/2021.
//  Copyright © 2021 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation
import RxSwift
import RxCoreLocation

class OpeningCompartmentController: WKInterfaceController {
    @IBOutlet var lblStatus: WKInterfaceLabel!
    @IBOutlet var btnReopen: WKInterfaceButton!
    @IBOutlet var btnDone: WKInterfaceButton!

    private var _parcelCollectManager: ParcelCollectManager!
    private let _locationManager = CLLocationManager()
    private let _disposeBag = DisposeBag()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        _locationManager.delegate = self
        
        let parcel = context as! Parcel
        _parcelCollectManager = .init(shipmentNumber: parcel.shipmentNumber, openCode: parcel.openCode!)
        _parcelCollectManager.delegate = self
    }

    override func didAppear() {
        super.didAppear()

        lblStatus.setText("Loading...")
        btnReopen.setEnabled(false)
        btnDone.setEnabled(false)

        _locationManager.rx
            .didUpdateLocations
            .asDriver()
            .compactMap({ (_, locations) -> CLLocation? in
                return locations.first
            })
            .drive { [weak self] (location) in
                self?._parcelCollectManager.start(location: location)
            }
            .disposed(by: _disposeBag)

        _locationManager.requestLocation()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func reopen() {
        lblStatus.setText("Reopening...")
        _parcelCollectManager.reopenCompartment()
    }

    @IBAction func done() {
        _parcelCollectManager.terminate()
    }
}

extension OpeningCompartmentController: ParcelCollectManagerDelegate {
    func parcelColectManager(_ manager: ParcelCollectManager, didChangeStatus status: ParcelCollectManager.CollectStatus) {
        btnReopen.setEnabled(false)
        btnDone.setEnabled(false)
        switch status {
        case .prepared:
            log.debug("Parcel manager prepared")
        case .validating:
            log.debug("Parcel validating...")
            lblStatus.setText("Validating...")
        case .validated:
            log.debug("Parcel validated")
            lblStatus.setText("Validated")

            manager.openCompartment()
            lblStatus.setText("Opening...")
        case .inProgress(compartmentStatus: let compartmentStatus):
            switch compartmentStatus {
            case .opened(reopened: let reopened, compartment: let compartment):
                if reopened {
                    log.debug("REOPENED: \(compartment.name)")
                    lblStatus.setText("REOPENED: \(compartment.name)")
                } else {
                    log.debug("OPENED: \(compartment.name)")
                    lblStatus.setText("OPENED: \(compartment.name)")
                }
            case .closed(initiali: let initiali):
                if !initiali {
                    log.debug("Compartment closed")
                    lblStatus.setText("Compartment closed")
                    btnReopen.setEnabled(true)
                    btnDone.setEnabled(true)
                } else {
                    log.debug("Compartment close")
                }
            }
        case .terminating:
            log.debug("Terminating...")
            lblStatus.setText("Terminating...")
        case .terminated:
            log.debug("Terminated")
            lblStatus.setText("Terminated")
            popToRootController()
        }
    }

    func parcelColectManager(_ manager: ParcelCollectManager, gotError error: Error) {
        log.error(error)
        lblStatus.setText("collecting error:\n\(error)")
        btnReopen.setEnabled(false)
        btnDone.setEnabled(false)
    }
}

extension OpeningCompartmentController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error(error)
        lblStatus.setText("Location manager error:\n\(error)")
    }
}
