//
//  CameraPreviewControllerWrapper.swift
//  rallie
//
//  Created by Xiexiao_Luo on 4/2/25.
//

import SwiftUI
import UIKit

struct CameraPreviewControllerWrapper: UIViewControllerRepresentable {
    let cameraController: CameraController

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            self.cameraController.startSession(in: vc.view)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // nothing needed
    }
}
