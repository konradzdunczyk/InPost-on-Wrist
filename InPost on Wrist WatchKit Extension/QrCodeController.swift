//
//  QrCodeController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 27/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import EFQRCode

class QrCodeController: WKInterfaceController {
    @IBOutlet var ivQrCode: WKInterfaceImage!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if let qrCodeData = context as? String {
            DispatchQueue.global(qos: .background).async {
                if let cgImage = EFQRCode.generate(content: qrCodeData) {
                    DispatchQueue.main.async {
                        self.ivQrCode.setImage(UIImage(cgImage: cgImage))
                    }
                }
            }
        }
    }
}
