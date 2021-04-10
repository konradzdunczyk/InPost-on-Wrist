//
//  MapController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 29/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit

class MapController: WKInterfaceController {
    @IBOutlet private var mapView: WKInterfaceMap!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        guard let pickupPoint = context as? PickUpPoint else { return }

        let pickupLocCoord = CLLocationCoordinate2D(latitude: pickupPoint.location.latitude,
                                                    longitude: pickupPoint.location.longitude)

        mapView.setShowsUserLocation(true)
        mapView.setRegion(MKCoordinateRegion(center: pickupLocCoord,
                                             span: .init(latitudeDelta: 0.005,
                                                         longitudeDelta: 0.005)))
        mapView.addAnnotation(pickupLocCoord, with: .green)
    }

}
