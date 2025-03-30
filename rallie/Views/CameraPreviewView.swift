//
//  CameraPreviewView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import SwiftUI

struct CameraPreviewView: UIViewControllerRepresentable {
    let controller: CameraController

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        controller.startSession(in: vc.view)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
