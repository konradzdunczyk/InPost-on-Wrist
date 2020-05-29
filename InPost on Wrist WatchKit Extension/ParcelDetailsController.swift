//
//  ParcelDetailsController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 29/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import RxSwift
import RxRelay
import RxCocoa

class LockerAddressButton: WKInterfaceButton {
    func setup(with pickupPoint: PickupPoint) {

    }
}

class CollectInfoButton: WKInterfaceButton {

}

class ParcelDetailsController: WKInterfaceController {
    @IBOutlet var lblParcelNumber: WKInterfaceLabel!
    @IBOutlet var lblExpireDate: WKInterfaceLabel!
    @IBOutlet var lblExpireTimer: WKInterfaceTimer!
    @IBOutlet var lblSender: WKInterfaceLabel!

    @IBOutlet private var lblOpenCode: WKInterfaceLabel!
    @IBOutlet private var lblPhoneNumber: WKInterfaceLabel!

    @IBOutlet private var lblLockerName: WKInterfaceLabel!
    @IBOutlet private var lblLockerAddress: WKInterfaceLabel!

    @IBOutlet var lockerButton: LockerAddressButton!
    @IBOutlet var collectInfoButton: CollectInfoButton!

    @IBOutlet var expiryGroup: WKInterfaceGroup!

    private var _parcel: Parcel!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        _parcel = context as? Parcel
        setup(with: _parcel)
    }

    @IBAction func openCompartment() {

    }

    @IBAction func showMap() {
        pushController(withName: "MapController",
                       context: _parcel.pickupPoint)
    }

    @IBAction func showQrCode() {
        guard let qrCode = _parcel.qrCode else { return }

        pushController(withName: "QrCodeController",
                       context: qrCode)
    }

    private func setup(with parcel: Parcel) {
        lblParcelNumber.setText(parcel.shipmentNumber)

        if let expiryDate = parcel.expiryDate {
            let df = DateFormatter()
            df.dateFormat = "dd.MM.yy HH:mm"
            lblExpireDate.setText(df.string(from: expiryDate))
            lblExpireTimer.setDate(expiryDate)
            lblExpireTimer.start()

            expiryGroup.setHidden(false)
        } else {
            expiryGroup.setHidden(true)
        }

        lblSender.setText(parcel.senderName)

        if let openCode = parcel.openCode {
            lblOpenCode.setText(openCode)
            lblPhoneNumber.setText(parcel.phoneNumber)
            collectInfoButton.setHidden(false)
        } else {
            collectInfoButton.setHidden(true)
        }

        let address: String? = {
            guard let addressDetails = parcel.pickupPoint.addressDetails else {
                return nil
            }

            return """
                \(addressDetails.street) \(addressDetails.buildingNumber)
                \(addressDetails.postCode) \(addressDetails.city)
            """
        }()

        lblLockerName.setText(parcel.pickupPoint.name)
        lblLockerAddress.setText(address)
    }
}
