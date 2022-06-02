//
//  CameraScan+Extension.swift
//  OptiScanBarcodeReader
//
//  Created by Dineshkumar Kandasamy on 01/03/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.

import UIKit
import Foundation
import AVFoundation
import opencv2
import Vision
import AudioToolbox

extension CameraScan: UINavigationControllerDelegate {
    
   private var hintsZxing:ZXDecodeHints {
        let formats = ZXDecodeHints()
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 1))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 2))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 3))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 4))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 5))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 6))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 7))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 8))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 9))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 10))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 11))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 12))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 13))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 14))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 15))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 16))
        formats.addPossibleFormat(ZXBarcodeFormat.init(rawValue: 17))
        return formats
    }
    
    /** This method runs the live camera pixelBuffer through tensorFlow to get the result.
     */
    func runModel(onPixelBuffer pixelBuffer: CVPixelBuffer) {
        // Run the live camera pixelBuffer through tensorFlow to get the result
        //        let pixImage = pixelBuffer.toImage()
        //        let fixOrient = self.fixOrientation(img: pixImage)
        
        result = YoloV4Classifier.shared.runModel(onFrame: pixelBuffer,previewSize: self.previewSize)
//        result = YoloV4Classifier.shared.runModelNew(onFrame: pixelBuffer,previewSize: self.previewSize)
        //        let src = Mat(uiImage: UIImage(named: "long_distance.jpg")!)
        ////
        //        let dst = Mat()
        //        opencv2.Core.normalize(src: src, dst: dst, alpha: 1.0, beta: 127.5, norm_type: NormTypes.NORM_INF)
        guard let displayResult = result else {
            return
        }
   
        for inference in displayResult.inferences {
            self.processResult(cropImage: inference.outputImage,previewWidth: inference.previewWidth,previewHeight: inference.previewHeight, inference: inference)
        }
        
        //      let width = CVPixelBufferGetWidth(pixelBuffer)
        //      let height = CVPixelBufferGetHeight(pixelBuffer)
        
        DispatchQueue.main.async {
            print("BEFORE DRAW: \(self.getCurrentMillis())")
            
            // Draws the bounding boxes and displays class names and confidence scores.
            self.drawAfterPerformingCalculations(onInferences: displayResult.inferences, withImageSize: CGSize(width: 0.0, height: 0.0))
            print("AFTER DRAW: \(self.getCurrentMillis())")
        }
    }
    
    internal func processResult(cropImage:UIImage,previewWidth:CGFloat,previewHeight:CGFloat,inference:Inference){
//        print("###### processResult")
//        print("AFTER performRotate: \(getCurrentMillis())")
        if inference.className == "QR" {
//            print("BEFORE QR DECODE: \(getCurrentMillis())")
            
//            print("CROPPED IMAGE SIZE",cropImage.size)
            var resultImage = UIImage()
            if isQrLongDistance(image: cropImage,previewWidth: previewWidth,previewHeight: previewHeight) {
//                print("QR Long Distance")
                resultImage = cropImage.upscaleQRcode()
                
                resultImage = SuperResolution.shared.convertImgToSRImg(inputImage: resultImage) ?? UIImage()
//                print("UPSCALE RESIZE",resultImage.size)
            } else {
                resultImage = cropImage
            }

            let points = NSMutableArray()
            let mat = Mat.init(uiImage: resultImage)
            let result = WeChatQRCode().detectAndDecode(img: mat, points: points)
            print("WECHAT RESULT",result)
            
            if result.first == nil || result.first == "" {
                self.decodeZxing(image: resultImage)
            } else {
//                print("###### FOUND QR",result.first ?? "")
//                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                found(code: result.first ?? "")
            }
//            print("AFTER QR DECODE: \(getCurrentMillis())")
//            print("AFTER ROTATE: \(getCurrentMillis())")
        } else {
            
            let resultImage:UIImage?
//            UIImageWriteToSavedPhotosAlbum(cropImage , self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            if isBarcodeLongDistance(image: cropImage,previewWidth: previewWidth,previewHeight: previewHeight) {
               print("BAR Long Distance")
                resultImage = cropImage.upscaleBarcode()
                //print("UPSCALE RESIZE",resultImage?.size)
            } else {
                resultImage = cropImage
            }


           // DispatchQueue.main.async {
           //     self.previewImage.image = cropImage
           // }
            let rotatedImage = self.processImage(image: resultImage ?? UIImage())
            self.decodeZxing(image: rotatedImage)
            
        }
        
        startCamera()
    }
    
//    //MARK: - Add image to Library
//       @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//           if let error = error {
//               // we got back an error!
//               print(error.localizedDescription)
//           } else {
//               print("Your image has been saved to your photos.")
//           }
//       }
    
    
   internal func decodeZxing(image:UIImage){
    
        let source: ZXLuminanceSource = ZXCGImageLuminanceSource(cgImage: image.cgImage)
        let binazer = ZXHybridBinarizer(source: source)
        let bitmap = ZXBinaryBitmap(binarizer: binazer)
//        print("###### BITMAP IMAGE WIDTH \(bitmap?.width ?? 0)")

        let reader = ZXMultiFormatReader()
        let hints = hintsZxing
       
        //print("###### DECODE BITMAP",try? reader.decode(bitmap, hints: hints))
       
        if let result = try? reader.decode(bitmap, hints: hints) {
            barDecodeCount = barDecodeCount + 1
//            print("$$$ $$$ $$ $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ $$$$$$$$$$$$$$ BAR DECODED RESULT COUNT",barDecodeCount)
//            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: result.text ?? "")
        } else {
            print("###### DECODE BITMAP Nil")
           // UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)

        }

    }
    
    private func fixOrientation(img: UIImage) -> UIImage {
        
        if ( img.imageOrientation == UIImage.Orientation.up ) {
            return img;
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        if ( img.imageOrientation == UIImage.Orientation.down || img.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: img.size.width, y: img.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        }
        
        if ( img.imageOrientation == UIImage.Orientation.left || img.imageOrientation == UIImage.Orientation.leftMirrored ) {
            transform = transform.translatedBy(x: img.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2.0))
        }
        
        if ( img.imageOrientation == UIImage.Orientation.right || img.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: 0, y: img.size.height);
            transform = transform.rotated(by: CGFloat(-Double.pi / 2.0));
        }
        
        if ( img.imageOrientation == UIImage.Orientation.upMirrored || img.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: img.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        if ( img.imageOrientation == UIImage.Orientation.leftMirrored || img.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: img.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx: CGContext = CGContext(data: nil, width: Int(img.size.width), height: Int(img.size.height),
                                       bitsPerComponent: img.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                       space: img.cgImage!.colorSpace!,
                                       bitmapInfo: img.cgImage!.bitmapInfo.rawValue)!;
        
        ctx.concatenate(transform)
        
        if ( img.imageOrientation == UIImage.Orientation.left ||
             img.imageOrientation == UIImage.Orientation.leftMirrored ||
             img.imageOrientation == UIImage.Orientation.right ||
             img.imageOrientation == UIImage.Orientation.rightMirrored ) {
            ctx.draw(img.cgImage!, in: CGRect(x: 0,y: 0,width: img.size.height,height: img.size.width))
        } else {
            ctx.draw(img.cgImage!, in: CGRect(x: 0,y: 0,width: img.size.width,height: img.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context and return it
        return UIImage(cgImage: ctx.makeImage()!)
    }
    
    private func isQrLongDistance(image:UIImage,previewWidth:CGFloat,previewHeight:CGFloat) ->Bool{
        let isLong = LongDistance().isLongDistanceQRImage(cropImageWidth: image.size.width, cropImageHeight: image.size.height, previewWidth: previewWidth, previewHeight: previewHeight)
        return isLong
    }
    
   private func isBarcodeLongDistance(image:UIImage,previewWidth:CGFloat,previewHeight:CGFloat) ->Bool{
        let isLong = LongDistance().isLongDistanceBarcodeImage(cropImageWidth: image.size.width, cropImageHeight: image.size.height, previewWidth: previewWidth, previewHeight: previewHeight)
        return isLong
    }
    
    /**
     This method takes the results, translates the bounding box rects to the current view, draws the bounding boxes, classNames and confidence scores of inferences.
     */
    func drawAfterPerformingCalculations(onInferences inferences: [Inference], withImageSize imageSize:CGSize) {

        self.overlayView.objectOverlays = []
        self.overlayView.setNeedsDisplay()
        
      let displayFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)

      guard !inferences.isEmpty else {
        return
      }

      var objectOverlays: [ObjectOverlay] = []

      for inference in inferences {

        // Translates bounding box rect to current view.
          var convertedRect = inference.rect
//          print("overlayView width",self.overlayView.bounds.size.width)
//          print("overlayView height",self.overlayView.bounds.size.height)
//          print("inference.rect",inference.rect)

        if convertedRect.origin.x < 0 {
            convertedRect.origin.x = self.edgeOffset
        }

        if convertedRect.origin.y < 0 {
          convertedRect.origin.y = self.edgeOffset
        }

          if convertedRect.maxY > self.overlayView.bounds.maxY {
              convertedRect.size.height = self.overlayView.bounds.maxY - convertedRect.origin.y - self.edgeOffset
          }

          if convertedRect.maxX > self.overlayView.bounds.maxX {
              convertedRect.size.width = self.overlayView.bounds.maxX - convertedRect.origin.x - self.edgeOffset
        }

        let confidenceValue = Int(inference.confidence * 100.0)
        let string = "\(inference.className)  (\(confidenceValue)%)"

        let size = string.size(usingFont: displayFont)
          print("Converted Rect",convertedRect)

          let objectOverlay = ObjectOverlay(name: string, borderRect: inference.boundingRect, nameStringSize: size, color: inference.displayColor, font: displayFont)
          print("BOUNDING Rect",inference.boundingRect)

        objectOverlays.append(objectOverlay)
      }

      // Hands off drawing to the OverlayView
      self.draw(objectOverlays: objectOverlays)

    }
    
    /** Calls methods to update overlay view with detected bounding boxes and class names.
     */
    func draw(objectOverlays: [ObjectOverlay]) {
//        print("&&&&&& &&&&&&& &&&&&&& OBJECT OVERLAY",objectOverlays)
        self.overlayView.objectOverlays = objectOverlays
        self.overlayView.setNeedsDisplay()
    }
    
    
}
 

private func getValidBarCode(_ codeFormat: Int) -> String {
    let codes = ["Aztec", "CODABAR", "Code 39", "Code 93", "Code 128", "Data Matrix", "EAN-8", "EAN-13", "ITF", "MaxiCode", "PDF417", "QR Code", "RSS 14", "RSS EXPANDED", "UPC-A", "UPC-E", "UPC/EAN"]
    if codeFormat < codes.count {
        return codes[codeFormat]
    } else {
        return "QR Code"
    }
}

