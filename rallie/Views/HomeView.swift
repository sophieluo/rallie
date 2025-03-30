//
//  ContentView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import SwiftUI

struct HomeView: View {
    @State private var showCamera = false

    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to Rallie")
                .font(.largeTitle)
                .padding(.bottom, 20)

            Button(action: {
                showCamera = true
            }) {
                Text("Start")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .fullScreenCover(isPresented: $showCamera) {
            LandscapeWrapper {
                CameraView()
            }
        }
    }
}
