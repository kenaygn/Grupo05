//
//  ARViewContainer.swift
//  Handy
//
//  Created by Mahmoud Aoata on 1.09.2024.
//

import SwiftUI
import Foundation
import ARKit

@available(iOS 14.0, *)
// Adicione 'public' aqui
public struct ARViewContainer: UIViewControllerRepresentable {
    
    @Binding var labelText: String
    var cameraFrame: CGRect
    @Binding var isCameraVisible: Bool
    
    // E adicione 'public' aqui também
    public init(labelText: Binding<String>, cameraFrame: CGRect, isCameraVisible: Binding<Bool>) {
        self._labelText = labelText
        self.cameraFrame = cameraFrame
        self._isCameraVisible = isCameraVisible
    }
    
    public func makeUIViewController(context: Context) -> ARViewController {
        let arViewController = ARViewController(cameraFrame: cameraFrame, isCameraVisible: isCameraVisible)
        
        arViewController.onLabelUpdate = { newValue in
            DispatchQueue.main.async {
                self.labelText = newValue
            }
        }
        
        return arViewController
    }
    
    public func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        uiViewController.arView.isHidden = !isCameraVisible
        uiViewController.cameraFrame = cameraFrame
    }
}
