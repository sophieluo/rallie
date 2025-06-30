//
//  ContentView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import SwiftUI

struct HomeView: View {
    @State private var showCamera = false
    @State private var showBluetoothTest = false
    @StateObject var cameraController = CameraController()

    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to Rallie")
                .font(.largeTitle)
                .padding(.bottom, 20)

            Button(action: {
                print("🎾 Start button tapped")
                showCamera = true
            }) {
                Text("Start")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 20)
            
            Button(action: {
                print("🔵 Bluetooth test button tapped")
                showBluetoothTest = true
            }) {
                HStack {
                    Image(systemName: "bluetooth")
                        .font(.title2)
                    Text("蓝牙测试")
                        .font(.title2)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue.opacity(0.8))
                .clipShape(Capsule())
            }
            
            Spacer()
        }
        .fullScreenCover(isPresented: $showCamera) {
            if #available(iOS 16.0, *) {
                CameraView(cameraController: cameraController)
            } else {
                // Fallback on earlier versions
            }
        }
        .sheet(isPresented: $showBluetoothTest) {
            BluetoothTestView()
        }
    }
}
