//
//  LandscapeHostingController.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import SwiftUI

class LandscapeHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }

    override var shouldAutorotate: Bool {
        return true
    }
}
