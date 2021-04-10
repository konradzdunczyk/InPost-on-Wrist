//
//  KZInterfaceController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 21/03/2021.
//  Copyright © 2021 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import Foundation


class KZInterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        addMenuItem(with: .info, title: "Log", action: #selector(showLog))
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @objc private func showLog() {
        pushController(withName: "LocationLogController",
                       context: nil)
    }
}
