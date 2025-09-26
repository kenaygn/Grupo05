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

@available(iOS 14.0, *)
public class ARViewController: UIViewController, @MainActor ARSessionDelegate {

    var arView: ARSCNView!
    var cameraFrame: CGRect
    var isCameraVisible: Bool
    
    var onLabelUpdate: ((String) -> Void)?
    
    var labelText: String = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.onLabelUpdate?(self.labelText)
            }
        }
    }
    
    private var frameCounter = 0
    private let handPosePredictionInterval = 30
    
    
    public init(cameraFrame: CGRect, isCameraVisible: Bool) {
        self.cameraFrame = cameraFrame
        self.isCameraVisible = isCameraVisible
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
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
                    }
                }
            }
        default:
            break
        }
    }
    
    func setupARView() {
        arView = ARSCNView(frame: cameraFrame)
        arView.session.delegate = self
        arView.isHidden = !isCameraVisible
        view.addSubview(arView)
        
        let configuration = ARFaceTrackingConfiguration()
        arView.session.run(configuration)

    }
    
    // MARK: - delegate funcs
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frameCounter += 1
        guard frameCounter % handPosePredictionInterval == 0 else { return }
        
        let pixelBuffer = frame.capturedImage
        
        let handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 1
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
        } catch {
            assertionFailure("Human Pose Request failed: \(error.localizedDescription)")
        }
        
        guard let handPoses = handPoseRequest.results, let handObservation = handPoses.first else {
            return
        }
        
        do {
            guard let keypointsMultiArray = try? handObservation.keypointsMultiArray() else { return }
            
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndGPU
            
            let model = try HandGestures(configuration: config)
            let prediction = try model.prediction(poses: keypointsMultiArray)
            
            if let confidence = prediction.labelProbabilities[prediction.label], confidence > 0.9 {
                renderHandPose(name: prediction.label)
            } else {
                clean()
            }
        } catch {
            print("Failure HandyModel: \(error.localizedDescription)")
        }
    }
    
    // MARK: - private funcs
    
    func renderHandPose(name: String) {
        switch name {
        case "aberta":
            labelText = "Mão Aberta"
        case "fechada":
            labelText = "Mão Fechada"
        default:
            clean()
        }
    }
    
    private func clean() {
        // Limpa os nós da cena para remover detecções antigas
        arView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        DispatchQueue.main.async {
            self.labelText = ""
        }
    }
}

