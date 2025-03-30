//
//  LandscapeWrapper.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import SwiftUI

struct LandscapeWrapper<Content: View>: UIViewControllerRepresentable {
    let content: () -> Content

    func makeUIViewController(context: Context) -> UIViewController {
        return LandscapeHostingController(rootView: content())
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
