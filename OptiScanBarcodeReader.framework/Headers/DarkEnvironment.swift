//
//  DarkEnvironmentUtils.swift
//  OptiScanBarcodeReader
//
//  Created by Dineshkumar Kandasamy on 30/05/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.
//

import UIKit
import opencv2
import VideoToolbox

extension CVPixelBuffer{
    
    func getCurrentMillis()->String {
       let dateFormatter : DateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss.SSSS"
       let date = Date()
       let dateString = dateFormatter.string(from: date)
       return dateString
   }
    
    func setBrightnessContrastOpencv() -> CVPixelBuffer {
        
        print("BEFORE setBrightnessContrastOpencv: \(getCurrentMillis())")
        let sourceImage = self.toImage()
        
        let src = Mat(uiImage: sourceImage)
        src.convert(to: src, rtype: -1, alpha: 1.2, beta: 1)
        let resultImage = src.toUIImage()
        return resultImage.toPixelBuffer()
       
    }
    
    func setBrightnessContrastAndroidOpencv() -> CVPixelBuffer {
        
        var img = Mat()
        let thresh = Mat()
        let sourceImage = self.toImage()
        img = Mat(uiImage: sourceImage)
        let lookUpTable = Mat(rows: 1, cols: 256, type: CvType.CV_8U)
        let lookUpTableTotal = lookUpTable.total()
        let lookUpTableChannels = Int(lookUpTable.channels())
        let arrayCount =  lookUpTableTotal * lookUpTableChannels
        var lookUpTableData = [UInt8](repeating: 0, count: arrayCount)
        for i in 0 ... lookUpTable.cols() - 1 {
            let power = pow(Double(i) / 255.0, 0.4) * 255.0
            lookUpTableData[Int(i)] = UInt8(power)
            //print(i)
        }
        do {
            try  lookUpTable.put(row: 0, col: 0, data: lookUpTableData)
        } catch {
            print("error")
        }
        Core.LUT(src: img, lut: lookUpTable, dst: thresh)
        let res = thresh.toCGImage()
        let resImage = UIImage(cgImage: res)
        return resImage.toPixelBuffer()
        
    }
    
}
