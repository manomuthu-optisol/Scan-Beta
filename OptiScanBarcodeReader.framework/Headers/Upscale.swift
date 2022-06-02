//
//  Upscale.swift
//  OptiScanBarcodeReader
//
//  Created by Dineshkumar Kandasamy on 30/05/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.
//

import Foundation
import opencv2

extension UIImage {
    
    func upscaleBarcode() -> UIImage {
        let srcImg = Mat(uiImage: self)
        let dstImg = Mat()
        Imgproc.resize(src: srcImg, dst: dstImg, dsize: Size2i(width: Int32(self.size.width) * scan_flow.up_scale.bar_code_edge_correction, height: Int32(self.size.height) * scan_flow.up_scale.bar_code_edge_correction))
        return dstImg.toUIImage()
    }
    
    func upscaleQRcode() -> UIImage {
        let srcImg = Mat(uiImage: self)
        let dstImg = Mat()
        Imgproc.resize(src: srcImg, dst: dstImg, dsize: Size2i(width: Int32(self.size.width) * scan_flow.up_scale.qr_code_edge_correction, height: Int32(self.size.height) * scan_flow.up_scale.qr_code_edge_correction))
        return dstImg.toUIImage()
    }
}
