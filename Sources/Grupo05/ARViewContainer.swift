//
//  ARViewContainer.swift
//  Handy
//
//  Created by Mahmoud Aoata on 1.09.2024.
//

import SwiftUI
import Foundation
import ARKit

@available(iOS 13.0, *)
struct ARViewContainer: UIViewControllerRepresentable {
    
    @Binding var labelText: String
    var cameraFrame: CGRect
    @Binding var isCameraVisible: Bool
    
    func makeUIViewController(context: Context) -> ARViewController {
        let arViewController = ARViewController(cameraFrame: cameraFrame, isCameraVisible: isCameraVisible)
        
        // 🔹 Conecta o retorno para atualizar o @Binding
        // Esta é a parte que faltava.
        arViewController.onLabelUpdate = { newValue in
            // Garante que a atualização seja na thread principal
            DispatchQueue.main.async {
                self.labelText = newValue
            }
        }
        
        return arViewController
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        // Você pode remover a linha abaixo, pois a comunicação agora é unidirecional (Controller -> View)
        // uiViewController.labelText = labelText
        uiViewController.arView.isHidden = !isCameraVisible
        uiViewController.cameraFrame = cameraFrame
    }
    
}
