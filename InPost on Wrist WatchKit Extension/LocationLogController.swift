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

class LocationLogController: WKInterfaceController {
    private var _logContent: String?
    @IBOutlet var lblLog: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        if let logFile = logFile {
            _logContent = try? String(contentsOf: logFile, encoding: .utf8)
        }
    }

    override func willActivate() {
        super.willActivate()

        if let logContent = _logContent {
            lblLog.setText(logContent)
        } else {
            lblLog.setText("Error while loading log content")
        }
    }
}
