//
//  ARViewController.swift
//  Handy
//
//  Created by Mahmoud Aoata on 1.09.2024.
//

//
//  ARViewController.swift
//  Handy
//
//  Created by Mahmoud Aoata on 1.09.2024.
//


import Foundation
import ARKit
import UIKit
import AVFoundation
import Vision
import CoreML


class ARViewController: UIViewController, @MainActor ARSessionDelegate {
    
    // vars
    var arView: ARSCNView!
    var cameraFrame: CGRect
    var isCameraVisible: Bool
    
    // callback para devolver o valor para quem criou o ARViewController
    var onLabelUpdate: ((String) -> Void)?
    
    var labelText: String = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onLabelUpdate?(self.labelText) // 🔹 devolve para o ContentView
            }
        }
    }
    
    private var frameCounter = 0
    private let handPosePredictionInterval = 30
    
    
    init(cameraFrame: CGRect, isCameraVisible: Bool) {
        self.cameraFrame = cameraFrame
        self.isCameraVisible = isCameraVisible
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraAccess()
        
    }
    
    func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            
            setupARView()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { enabled in
                DispatchQueue.main.async {
                    if enabled {
                        self.setupARView()
                    } else {
                        print("not working...")
                    }
                }
            }
        case .denied, .restricted:
            print("Check settings..")
            
        @unknown default:
            print("Error")
        }
    }
    
    func setupARView() {
        arView = ARSCNView(frame: cameraFrame)
        arView.session.delegate = self
        arView.isHidden = !isCameraVisible
        view.addSubview(arView)
        
        // generak world tracking
        
        let configuration = ARWorldTrackingConfiguration()
        
        // enable the front camera
        
        if ARFaceTrackingConfiguration.isSupported {
            let faceTrackingConfig = ARFaceTrackingConfiguration()
            arView.session.run(faceTrackingConfig)
        } else {
            // not supported
            // show an alert
            arView.session.run(configuration)
        }
        
    }
    
    // MARK: - delegate funcs
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frameCounter += 1
        let pixelBuffer = frame.capturedImage
        guard #available(iOS 14.0, *) else { return }
        
        let handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 1
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
        } catch {
            assertionFailure("Human Pose Request failed: \(error.localizedDescription)")
        }
        
        guard let handPoses = handPoseRequest.results, !handPoses.isEmpty else {
            // no effects to draw
            return
        }
        
        let handObservations = handPoses.first
        
        
        if frameCounter % handPosePredictionInterval == 0 {
            guard let keypointsMultiArray = try? handObservations!.keypointsMultiArray() else {
                fatalError("Failed to create key points array")
            }
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .cpuAndGPU
                
                // ML model version setup
                // Aqui ele pega o modelo
                let model = try HandGestures.init(configuration: config)
                
                let handPosePrediction = try model.prediction(poses: keypointsMultiArray)
                let confidence = handPosePrediction.labelProbabilities[handPosePrediction.label]!
                DispatchQueue.main.async { [weak self] in
                    guard self != nil else { return }
                }
                print("labelProbabilities \(handPosePrediction.labelProbabilities)")

                // render handpose effect
                if confidence > 0.9 {

                    print("handPosePrediction: \(handPosePrediction.label)")
                    renderHandPose(name: handPosePrediction.label)
                } else {
                    print("handPosePrediction: \(handPosePrediction.label)")
//                    cleanEmojii()

                }
                
            } catch let error {
                print("Failure HandyModel: \(error.localizedDescription)")
            }
            
            
        }
    }
    
    // MARK: - private funcs
    
    func renderHandPose(name: String) {
        switch name {
        case "aberta":
            labelText = "aberta"
            print("Aberta detectada")
            
        case "fechada":
            labelText = "fechada"
            print("fechada handpose dedicted")
            
            
        default:
            print("Remove nodes")
            clean()
        }
    }
    
    
    private func clean() {

        DispatchQueue.main.async {
            self.labelText = ""
        }
    }
    
    
    enum Pose: String {
        case fechada = "fechada"
        case aberta = "aberta"
    
    }
    
    
}

