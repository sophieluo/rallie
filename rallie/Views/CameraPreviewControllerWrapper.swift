//
//  CameraPreviewControllerWrapper.swift
//  rallie
//
//  Created by Xiexiao_Luo on 4/2/25.
//

import SwiftUI
import UIKit

struct CameraPreviewControllerWrapper: UIViewControllerRepresentable {
    let controller: CameraController

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            controller.startSession(in: viewController.view)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No-op
    }
}
