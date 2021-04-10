//
//  ParcelsController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import Alamofire
import RxSwift
import RxRelay
import RxCocoa
import CoreLocation

//class MockParcelService: ParcelService {
//    func getParcels(updatedAfter: Date?, completion: @escaping (Result<[Parcel], AFError>) -> Void) {
//        let parcel = Parcel(shipmentNumber: "691409068002670122388504",
//                            shipmentType: "ready_to_pickup",
//                            status: "",
//                            statusHistory: [],
//                            isObserved: false,
//                            expiryDate: Date(timeIntervalSinceNow: 48 * 60 * 60),
//                            pickupDate: nil,
//                            openCode: "336504",
//                            phoneNumber: "504912201",
//                            qrCode: "P|504912201|336504",
//                            pickupPoint: PickUpPoint(name: "test locker",
//                                                     status: "",
//                                                     location: Location(latitude: 52.18154, longitude: 21.02116),
//                                                     locationDescription: nil,
//                                                     addressDetails: nil,
//                                                     virtual: 0,
//                                                     type: []),
//                            senderName: "testowy",
//                            storedDate: nil,
//                            isMobileCollectPossible: true)
//
//        completion(.success([parcel]))
//    }
//}

protocol ParcelsListViewModelType {
    var rx_parcels: Observable<[Parcel]> { get }

    func willActivate()
    func selectParcel(at index: Int)
}

class ParcelsListViewModel: ParcelsListViewModelType {
    var parcelService: ParcelService = NetworkParcelService()
//    var parcelService: ParcelService = MockParcelService()
    var parcelSelected: ((Parcel) -> Void)?
    var locationManager = CLLocationManager()

    var rx_parcels: Observable<[Parcel]> {
        return _parcels.asObservable()
    }

    private let _parcels = BehaviorRelay<[Parcel]>(value: [])

    func willActivate() {
        var c = DateComponents()
        c.calendar = Calendar.autoupdatingCurrent
        c.timeZone = TimeZone.autoupdatingCurrent
        c.year = 2021
        c.month = 3
        c.day = 10

        parcelService.getParcels(updatedAfter: c.date!) { [weak self] (result) in
            switch result {
            case .success(let parcels):
                let filteredParcels = parcels
                    .filter({ $0.status == "ready_to_pickup" })
                    .filter({
                        guard let multiComp = $0.multiCompartment else { return true }

                        return multiComp.shipmentNumbers != nil
                    })

                self?._parcels.accept(filteredParcels)
            case .failure(let error):
                self?._parcels.accept([])
                print(error)
            }
        }

        locationManager.requestWhenInUseAuthorization()
    }

    func selectParcel(at index: Int) {
        parcelSelected?(_parcels.value[index])
    }
}

class ParcelsController: KZInterfaceController {
    @IBOutlet var table: WKInterfaceTable!

    private var _viewModel: ParcelsListViewModelType!
    private let disposeBag = DisposeBag()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        _viewModel = context as? ParcelsListViewModelType
        _viewModel.rx_parcels
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] (parcels) in
                self?.setupRows(with: parcels)
            })
        .disposed(by: disposeBag)
    }

    override func didAppear() {
        super.didAppear()

        _viewModel.willActivate()
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        _viewModel.selectParcel(at: rowIndex)
    }

    private func setupRows(with parcels: [Parcel]) {
        table.setNumberOfRows(parcels.count, withRowType: "ParcelRowControllerIdentifier")
        for (index, parcel) in parcels.enumerated() {
            guard let row = table.rowController(at: index) as? ParcelRowController else { continue }

            row.setup(with: parcel)
        }
    }
}
