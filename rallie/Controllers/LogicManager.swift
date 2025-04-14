import Foundation
import Combine

class LogicManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let bluetoothManager: BluetoothManager  // Replace with your BLE implementation

    init(playerPositionPublisher: Published<CGPoint?>.Publisher, bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager

        // Subscribe to player position updates
        playerPositionPublisher
            .compactMap { $0 }
            .sink { [weak self] position in
                self?.handleNewPosition(position)
            }
            .store(in: &cancellables)
    }

    private func handleNewPosition(_ point: CGPoint) {
        print("📡 LogicManager received player position: \(point)")

        // Example logic — you can replace this with actual rules
        let command: String
        if point.x < 2 {
            command = "LEFT"
        } else if point.x > 6 {
            command = "RIGHT"
        } else {
            command = "CENTER"
        }

        bluetoothManager.sendCommand(command)
    }
}
