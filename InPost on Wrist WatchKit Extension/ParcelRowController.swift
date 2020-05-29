//
//  ParcelRowController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit

class ParcelRowController: NSObject {
    @IBOutlet var lblParcelNumber: WKInterfaceLabel!
    @IBOutlet var expireTimeer: WKInterfaceTimer!
    @IBOutlet var lblSender: WKInterfaceLabel!
    @IBOutlet var lblLocker: WKInterfaceLabel!

    func setup(with parcel: Parcel) {
        lblParcelNumber.setText("..." + String(parcel.shipmentNumber.suffix(8)))

        if let exppireDate = parcel.expiryDate {
            expireTimeer.setDate(exppireDate)
            expireTimeer.start()
            expireTimeer.setHidden(false)
        } else {
            expireTimeer.setHidden(true)
        }

        lblSender.setText(parcel.senderName)
        lblLocker.setText(parcel.pickupPoint.name)
    }
}
