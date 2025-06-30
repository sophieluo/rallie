import SwiftUI

struct BluetoothTestView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    
    // Command parameters
    @State private var upperWheelSpeed: String = "0"
    @State private var lowerWheelSpeed: String = "0"
    @State private var pitchAngle: String = "0"
    @State private var yawAngle: String = "0"
    @State private var feedSpeed: String = "0"
    @State private var controlBit: String = "0"
    
    // Raw command input
    @State private var rawCommandInput: String = "5A A5 83 00 00 00 00 00 00 00"
    @State private var showRawCommandInput: Bool = false
    
    // UI States
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("蓝牙状态")) {
                    HStack {
                        Text("连接状态:")
                        Spacer()
                        Text(bluetoothManager.connectionState.rawValue)
                            .foregroundColor(stateColor)
                    }
                    
                    if let response = bluetoothManager.lastReceivedResponse {
                        HStack {
                            Text("最近响应:")
                            Spacer()
                            Text(response.description)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("响应时间:")
                            Spacer()
                            Text(formatDate(response.timestamp))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        bluetoothManager.startScanning()
                    }) {
                        HStack {
                            Spacer()
                            Text("搜索设备")
                            Spacer()
                        }
                    }
                    .disabled(bluetoothManager.connectionState == .scanning || 
                              bluetoothManager.connectionState == .connecting)
                    
                    if bluetoothManager.connectionState == .connected {
                        Button(action: {
                            bluetoothManager.disconnect()
                        }) {
                            HStack {
                                Spacer()
                                Text("断开连接")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section(header: Text("命令参数")) {
                    Toggle("使用原始命令输入", isOn: $showRawCommandInput)
                    
                    if showRawCommandInput {
                        TextField("原始命令 (十六进制, 空格分隔)", text: $rawCommandInput)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        HStack {
                            Text("上轮转速:")
                            Spacer()
                            TextField("0-100", text: $upperWheelSpeed)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("下轮转速:")
                            Spacer()
                            TextField("0-100", text: $lowerWheelSpeed)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("Pitch角度:")
                            Spacer()
                            TextField("0-90", text: $pitchAngle)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("Yaw角度:")
                            Spacer()
                            TextField("0-90", text: $yawAngle)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("上球速度:")
                            Spacer()
                            TextField("0-100", text: $feedSpeed)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("控制位:")
                            Spacer()
                            Picker("", selection: $controlBit) {
                                Text("停止发球 (0)").tag("0")
                                Text("启动发球 (1)").tag("1")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 200)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        sendCommand()
                    }) {
                        HStack {
                            Spacer()
                            Text("发送命令")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(bluetoothManager.connectionState != .connected)
                }
                
                Section(header: Text("协议说明")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rallie 蓝牙通信协议 v0.3")
                            .font(.headline)
                        
                        Text("指令帧结构 (10字节):")
                            .font(.subheadline)
                            .padding(.top, 5)
                        
                        Text("Byte 0: 数据头1 (0x5A)\nByte 1: 数据头2 (0xA5)\nByte 2: 数据来源 (0x83)\nByte 3: 上轮转速 (0-100)\nByte 4: 下轮转速 (0-100)\nByte 5: Pitch角度 (0-90)\nByte 6: Yaw角度 (0-90)\nByte 7: 上球速度 (0-100)\nByte 8: 控制位 (0/1)\nByte 9: CRC16")
                            .font(.system(.caption, design: .monospaced))
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("蓝牙测试")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
            }
        }
    }
    
    private var stateColor: Color {
        switch bluetoothManager.connectionState {
        case .connected:
            return .green
        case .disconnected:
            return .red
        case .failed:
            return .red
        case .scanning, .connecting:
            return .orange
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func sendCommand() {
        if showRawCommandInput {
            sendRawCommand()
        } else {
            sendStructuredCommand()
        }
    }
    
    private func sendStructuredCommand() {
        guard let upperWheel = UInt8(upperWheelSpeed),
              let lowerWheel = UInt8(lowerWheelSpeed),
              let pitch = UInt8(pitchAngle),
              let yaw = UInt8(yawAngle),
              let feed = UInt8(feedSpeed),
              let control = UInt8(controlBit) else {
            
            alertMessage = "请输入有效的数值参数"
            showAlert = true
            return
        }
        
        bluetoothManager.sendCommand(
            upperWheelSpeed: upperWheel,
            lowerWheelSpeed: lowerWheel,
            pitchAngle: pitch,
            yawAngle: yaw,
            feedSpeed: feed,
            controlBit: control
        )
    }
    
    private func sendRawCommand() {
        // Parse hex string into bytes
        let components = rawCommandInput.components(separatedBy: .whitespacesAndNewlines)
        var bytes: [UInt8] = []
        
        for component in components {
            if component.isEmpty { continue }
            
            if let byte = UInt8(component, radix: 16) {
                bytes.append(byte)
            } else {
                alertMessage = "无效的十六进制值: \(component)"
                showAlert = true
                return
            }
        }
        
        if bytes.count != 10 {
            alertMessage = "命令必须为10字节 (当前: \(bytes.count)字节)"
            showAlert = true
            return
        }
        
        bluetoothManager.sendRawCommand(bytes)
    }
}

struct BluetoothTestView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothTestView()
    }
}
