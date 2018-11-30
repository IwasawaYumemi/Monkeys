//
//  ViewController.swift
//  BabyDriver
//
//  Created by 岩澤 忠恭 on 2018/11/30.
//  Copyright © 2018年 岩澤 忠恭. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseMLVision

class ViewController: UIViewController {
    private let smilingThreshold: CGFloat = 0.95
    private let cryingEyeThreshold: CGFloat = 0.1

    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.low
        return session
    }()

    private lazy var sessionQueue = DispatchQueue(label: "hogehogeLabel")

    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: captureSession)
        
        preview.bounds = CGRect(x: 0, y: 0,
                                width: view.bounds.width,
                                height: view.bounds.height)
        
        preview.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        preview.videoGravity = AVLayerVideoGravity.resize
        
        return preview
    }()

    private lazy var vision = Vision.vision()

    private var lastFrame: CMSampleBuffer?

    private let videoUsecase = VideoVisionUsecase()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCaptureSessionOutput()
        setUpCaptureSessionInput()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.layer.addSublayer(previewLayer)

        startSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopSession()
    }
    
    private func startSession() {
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }
    
    private func stopSession() {
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }
    
    private func setUpCaptureSessionOutput() {
        sessionQueue.async {
            self.captureSession.beginConfiguration()
            // When performing latency tests to determine ideal capture settings,
            // run the app in 'release' mode to get accurate performance metrics
            self.captureSession.sessionPreset = AVCaptureSession.Preset.medium
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings =
                [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
            let outputQueue = DispatchQueue(label: "hogehoge")
            output.setSampleBufferDelegate(self, queue: outputQueue)
            guard self.captureSession.canAddOutput(output) else {
                print("Failed to add capture session output.")
                return
            }
            self.captureSession.addOutput(output)
            self.captureSession.commitConfiguration()
        }
    }

    private func setUpCaptureSessionInput() {
        sessionQueue.async {
            let cameraPosition: AVCaptureDevice.Position = .front
            guard let device = self.captureDevice(forPosition: cameraPosition) else {
                print("Failed to get capture device for camera position: \(cameraPosition)")
                return
            }
            do {
                self.captureSession.beginConfiguration()
                let currentInputs = self.captureSession.inputs
                for input in currentInputs {
                    self.captureSession.removeInput(input)
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                guard self.captureSession.canAddInput(input) else {
                    print("Failed to add capture session input.")
                    return
                }
                self.captureSession.addInput(input)
                self.captureSession.commitConfiguration()
            } catch {
                print("Failed to create capture device input: \(error.localizedDescription)")
            }
        }
    }
    
    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        return discoverySession.devices.first { $0.position == position }
    }
    
    private func detectFacesOnDevice(in image: VisionImage, width: CGFloat, height: CGFloat) {
        let options = VisionFaceDetectorOptions()
        options.landmarkType = .all
        options.classificationType = .all

        let faceDetector = vision.faceDetector(options: options)
        faceDetector.detect(in: image) { [weak self] (faces, error) in
            guard error == nil, let faces = faces, !faces.isEmpty else {
                return
            }

            for face in faces {
                self?.inspectFacialExpression(face: face)
            }
        }
    }
    
    private func inspectFacialExpression(face: VisionFace) {
        // TODO なく表情を定義
        if face.hasRightEyeOpenProbability && face.hasLeftEyeOpenProbability {
            let rightEyeOpenProb = face.rightEyeOpenProbability
            let leftEyeOpenProb = face.leftEyeOpenProbability
            
            if (rightEyeOpenProb < cryingEyeThreshold || leftEyeOpenProb < cryingEyeThreshold) {
                
            }
        }
        
        if face.hasSmilingProbability {
            let smileProb = face.smilingProbability
            if smileProb > smilingThreshold {
                amuse()
            }
        }
    }
    
    private func amuse() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let amuseViewController = storyboard.instantiateViewController(withIdentifier: "AmuseViewController") as? AmuseViewController else { return }
        
        
        stopSession()
        present(amuseViewController, animated: true, completion: nil)
    }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer.")
            return
        }

        lastFrame = sampleBuffer
        let visionImage = VisionImage(buffer: sampleBuffer)

        let metadata = VisionImageMetadata()

        let orientation = videoUsecase.imageOrientation(fromDevicePosition: .front)

        let visionOrientation = videoUsecase.visionImageOrientation(from: orientation)
        metadata.orientation = visionOrientation
        visionImage.metadata = metadata

        let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
        
        detectFacesOnDevice(in: visionImage, width: imageWidth, height: imageHeight)

    }
}


