//
//  VideoVisionUsecase.swift
//  BabyDriver
//
//  Created by 岩澤 忠恭 on 2018/11/30.
//  Copyright © 2018年 岩澤 忠恭. All rights reserved.
//

import AVFoundation
import UIKit
import FirebaseMLVision

class VideoVisionUsecase {
    
    func imageOrientation(fromDevicePosition devicePosition: AVCaptureDevice.Position = .back) -> UIImage.Orientation {
        
        var deviceOrientation = UIDevice.current.orientation
        
        if deviceOrientation == .faceDown
            || deviceOrientation == .faceUp
            || deviceOrientation == .unknown {
            deviceOrientation = currentUIOrientation()
        }
        
        switch deviceOrientation {
        case .portrait:
            return devicePosition == .front ? .leftMirrored : .right
            
        case .landscapeLeft:
            return devicePosition == .front ? .downMirrored : .up
            
        case .portraitUpsideDown:
            return devicePosition == .front ? .rightMirrored : .left
            
        case .landscapeRight:
            return devicePosition == .front ? .upMirrored : .down
            
        case .faceDown, .faceUp, .unknown:
            return .up
        }
    }

    func visionImageOrientation(from imageOrientation: UIImage.Orientation) -> VisionDetectorImageOrientation {
        
        switch imageOrientation {
        case .up:
            return .topLeft
            
        case .down:
            return .bottomRight
            
        case .left:
            return .leftBottom
            
        case .right:
            return .rightTop
            
        case .upMirrored:
            return .topRight
            
        case .downMirrored:
            return .bottomLeft
            
        case .leftMirrored:
            return .leftTop
            
        case .rightMirrored:
            return .rightBottom
            
        }
    }
}

// MARK: - Private
extension VideoVisionUsecase{
    
    private func currentUIOrientation() -> UIDeviceOrientation {
        
        let deviceOrientation = { () -> UIDeviceOrientation in
            
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                return .landscapeRight
                
            case .landscapeRight:
                return .landscapeLeft
                
            case .portraitUpsideDown:
                return .portraitUpsideDown
                
            case .portrait, .unknown:
                return .portrait
            }
        }
        
        guard Thread.isMainThread else {
            var currentOrientation: UIDeviceOrientation = .portrait
            DispatchQueue.main.sync {
                currentOrientation = deviceOrientation()
            }
            return currentOrientation
        }
        
        return deviceOrientation()
    }

}
