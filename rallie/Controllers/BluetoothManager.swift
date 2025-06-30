import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?

    // Default UUIDs to use if not found in Info.plist
    private var serviceUUID: CBUUID = CBUUID(string: "FFE0")
    private var characteristicUUID: CBUUID = CBUUID(string: "FFE1")
    
    // Hardcoded target peripheral UUID
    private let targetPeripheralUUID = "A8A83D7C-5F32-A19A-42A1-4446F3C67D85"
    
    // Connection state for UI feedback
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastReceivedResponse: BluetoothResponse?
    @Published var bluetoothState: CBManagerState = .unknown
    
    // Protocol constants
    private let headerByte1: UInt8 = 0x5A
    private let headerByte2: UInt8 = 0xA5
    private let sourceIdentifier: UInt8 = 0x83 // App to MCU identifier
    private let mcu2AppIdentifier: UInt8 = 0x82 // MCU to App identifier
    
    enum ConnectionState: String {
        case disconnected = "断开连接"
        case scanning = "搜索中..."
        case connecting = "连接中..."
        case connected = "已连接"
        case failed = "连接失败"
    }
    
    // Response from MCU
    struct BluetoothResponse {
        let responseCode: UInt8
        let timestamp: Date
        
        var description: String {
            switch responseCode {
            case 0: return "拒绝响应"
            case 1: return "接受并开始响应"
            case 2: return "完成响应"
            default: return "未知响应: \(responseCode)"
            }
        }
    }

    override init() {
        super.init()

        // Try to get UUIDs from Info.plist, but use defaults if not available
        if let serviceUUIDString = Bundle.main.object(forInfoDictionaryKey: "BLE_SERVICE_UUID") as? String,
           let characteristicUUIDString = Bundle.main.object(forInfoDictionaryKey: "BLE_CHARACTERISTIC_UUID") as? String,
           let validServiceUUID = UUID(uuidString: serviceUUIDString),
           let validCharUUID = UUID(uuidString: characteristicUUIDString) {
            
            self.serviceUUID = CBUUID(nsuuid: validServiceUUID)
            self.characteristicUUID = CBUUID(nsuuid: validCharUUID)
            print("🔵 BluetoothManager initialized with UUIDs from Info.plist")
        } else {
            // Using default UUIDs
            print("🔵 BluetoothManager initialized with default UUIDs")
        }
        
        // Always initialize the centralManager
        // Use main queue for UI updates
        centralManager = CBCentralManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    // Public method to manually start scanning
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("⚠️ Cannot start scanning - Bluetooth not ready: \(bluetoothStateDescription(centralManager.state))")
            connectionState = .failed
            return
        }
        
        connectionState = .scanning
        
        // Try to retrieve the peripheral directly by UUID first
        if let uuid = UUID(uuidString: targetPeripheralUUID),
           let peripheral = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first {
            print("🔵 Found target peripheral directly: \(peripheral.name ?? "Unknown")")
            targetPeripheral = peripheral
            connectionState = .connecting
            centralManager.connect(peripheral, options: nil)
            peripheral.delegate = self
            return
        }
        
        // If direct retrieval fails, scan for services
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        print("🔍 Scanning for peripherals with service UUID: \(serviceUUID.uuidString)")
    }
    
    // Helper function to get a description of the Bluetooth state
    private func bluetoothStateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .unknown:
            return "Unknown"
        case .resetting:
            return "Resetting"
        case .unsupported:
            return "Unsupported"
        case .unauthorized:
            return "Unauthorized"
        case .poweredOff:
            return "Powered Off"
        case .poweredOn:
            return "Powered On"
        @unknown default:
            return "Unknown"
        }
    }
    
    // Public method to disconnect
    func disconnect() {
        if let peripheral = targetPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectionState = .disconnected
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        
        print("🔵 Bluetooth state changed: \(bluetoothStateDescription(central.state))")
        
        switch central.state {
        case .poweredOn:
            // Bluetooth is on and ready
            connectionState = .disconnected
            // Don't automatically start scanning here
        case .poweredOff:
            print("⚠️ Bluetooth is powered off")
            connectionState = .failed
        case .unauthorized:
            print("⚠️ Bluetooth permission denied")
            connectionState = .failed
        case .unsupported:
            print("⚠️ Bluetooth is not supported on this device")
            connectionState = .failed
        default:
            connectionState = .disconnected
            print("⚠️ Bluetooth not available: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("🔵 Discovered peripheral: \(peripheral.name ?? "Unknown") - UUID: \(peripheral.identifier.uuidString)")
        
        // Check if this is our target peripheral
        if peripheral.identifier.uuidString.uppercased() == targetPeripheralUUID.uppercased() {
            print("✅ Found target peripheral!")
            targetPeripheral = peripheral
            centralManager.stopScan()
            connectionState = .connecting
            centralManager.connect(peripheral, options: nil)
            peripheral.delegate = self
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to peripheral")
        connectionState = .connected
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        connectionState = .failed
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Disconnected from peripheral: \(error?.localizedDescription ?? "No error")")
        connectionState = .disconnected
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        for char in characteristics {
            if char.uuid == characteristicUUID {
                self.commandCharacteristic = char
                
                // Enable notifications to receive data from peripheral
                peripheral.setNotifyValue(true, for: char)
                
                print("✅ Ready to send commands")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Error receiving data: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value, !data.isEmpty else { return }
        
        // Process the received data according to protocol
        processReceivedData(data)
    }
    
    private func processReceivedData(_ data: Data) {
        // Check if data matches the expected format (5 bytes)
        guard data.count == 5 else {
            print("⚠️ Received data with unexpected length: \(data.count) bytes")
            return
        }
        
        let bytes = [UInt8](data)
        
        // Verify header and source
        guard bytes[0] == headerByte1 && bytes[1] == headerByte2 && bytes[2] == mcu2AppIdentifier else {
            print("⚠️ Received data with invalid header or source")
            return
        }
        
        // Verify CRC
        let calculatedCRC = calculateCRC(Array(bytes[0..<4]))
        guard calculatedCRC == bytes[4] else {
            print("⚠️ CRC check failed. Expected: \(calculatedCRC), Received: \(bytes[4])")
            return
        }
        
        // Process response code
        let responseCode = bytes[3]
        lastReceivedResponse = BluetoothResponse(responseCode: responseCode, timestamp: Date())
        
        print("📥 Received response: \(responseCode) - \(lastReceivedResponse?.description ?? "Unknown")")
    }
    
    // Send command with the new protocol format
    func sendCommand(upperWheelSpeed: UInt8, lowerWheelSpeed: UInt8, pitchAngle: UInt8, 
                    yawAngle: UInt8, feedSpeed: UInt8, controlBit: UInt8) {
        
        guard let peripheral = targetPeripheral,
              let characteristic = commandCharacteristic else {
            print("⚠️ Cannot send command – not connected")
            return
        }
        
        // Validate input parameters
        let upperWheel = min(100, upperWheelSpeed)
        let lowerWheel = min(100, lowerWheelSpeed)
        let pitch = min(90, pitchAngle)
        let yaw = min(90, yawAngle)
        let feed = min(100, feedSpeed)
        let control = min(1, controlBit) // Only 0 or 1 for now
        
        // Create command bytes
        var commandBytes: [UInt8] = [
            headerByte1,      // 0x5A
            headerByte2,      // 0xA5
            sourceIdentifier, // 0x83
            upperWheel,       // 0-100
            lowerWheel,       // 0-100
            pitch,            // 0-90
            yaw,              // 0-90
            feed,             // 0-100
            control           // 0/1
        ]
        
        // Calculate CRC and append
        let crc = calculateCRC(commandBytes)
        commandBytes.append(crc)
        
        // Convert to Data and send
        let data = Data(commandBytes)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        
        print("📤 Sent command: upperWheel=\(upperWheel), lowerWheel=\(lowerWheel), pitch=\(pitch), yaw=\(yaw), feed=\(feed), control=\(control), crc=\(crc)")
    }
    
    // Send raw command bytes for testing
    func sendRawCommand(_ commandBytes: [UInt8]) {
        guard let peripheral = targetPeripheral,
              let characteristic = commandCharacteristic else {
            print("⚠️ Cannot send command – not connected")
            return
        }
        
        // Convert to Data and send
        let data = Data(commandBytes)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        
        print("📤 Sent raw command: \(commandBytes.map { String(format: "%02X", $0) }.joined(separator: " "))")
    }
    
    // Simple CRC calculation
    private func calculateCRC(_ bytes: [UInt8]) -> UInt8 {
        var crc: UInt8 = 0
        for byte in bytes {
            crc ^= byte
        }
        return crc
    }
}
