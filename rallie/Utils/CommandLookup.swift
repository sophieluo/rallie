import Foundation
import CoreGraphics

struct CommandLookup {
    // Protocol constants
    private static let headerByte1: UInt8 = 0x5A
    private static let headerByte2: UInt8 = 0xA5
    private static let sourceIdentifier: UInt8 = 0x83
    
    // Fallback command parameters if no zone match is found
    static let fallbackCommand = BluetoothCommand(
        upperWheelSpeed: 50,
        lowerWheelSpeed: 50,
        pitchAngle: 45,
        yawAngle: 45,
        feedSpeed: 50,
        controlBit: 0
    )

    // Command structure for the new protocol
    struct BluetoothCommand {
        let upperWheelSpeed: UInt8 // 0-100
        let lowerWheelSpeed: UInt8 // 0-100
        let pitchAngle: UInt8      // 0-90
        let yawAngle: UInt8        // 0-90
        let feedSpeed: UInt8       // 0-100
        let controlBit: UInt8      // 0/1
        
        // Convert to byte array (without CRC)
        func toByteArray() -> [UInt8] {
            return [
                CommandLookup.headerByte1,
                CommandLookup.headerByte2,
                CommandLookup.sourceIdentifier,
                upperWheelSpeed,
                lowerWheelSpeed,
                pitchAngle,
                yawAngle,
                feedSpeed,
                controlBit
            ]
        }
        
        // Calculate CRC and return complete command
        func toCompleteByteArray() -> [UInt8] {
            let bytes = toByteArray()
            let crc = CommandLookup.calculateCRC(bytes)
            return bytes + [crc]
        }
    }

    // Predefined commands for 4x4 grid zones (zoneID -> BluetoothCommand)
    private static let hardcodedCommands: [Int: BluetoothCommand] = [
        // Row 1 (back court)
        0: BluetoothCommand(upperWheelSpeed: 70, lowerWheelSpeed: 70, pitchAngle: 30, yawAngle: 20, feedSpeed: 60, controlBit: 1),
        1: BluetoothCommand(upperWheelSpeed: 70, lowerWheelSpeed: 70, pitchAngle: 30, yawAngle: 40, feedSpeed: 60, controlBit: 1),
        2: BluetoothCommand(upperWheelSpeed: 70, lowerWheelSpeed: 70, pitchAngle: 30, yawAngle: 60, feedSpeed: 60, controlBit: 1),
        3: BluetoothCommand(upperWheelSpeed: 70, lowerWheelSpeed: 70, pitchAngle: 30, yawAngle: 80, feedSpeed: 60, controlBit: 1),
        
        // Row 2
        4: BluetoothCommand(upperWheelSpeed: 60, lowerWheelSpeed: 60, pitchAngle: 40, yawAngle: 20, feedSpeed: 50, controlBit: 1),
        5: BluetoothCommand(upperWheelSpeed: 60, lowerWheelSpeed: 60, pitchAngle: 40, yawAngle: 40, feedSpeed: 50, controlBit: 1),
        6: BluetoothCommand(upperWheelSpeed: 60, lowerWheelSpeed: 60, pitchAngle: 40, yawAngle: 60, feedSpeed: 50, controlBit: 1),
        7: BluetoothCommand(upperWheelSpeed: 60, lowerWheelSpeed: 60, pitchAngle: 40, yawAngle: 80, feedSpeed: 50, controlBit: 1),
        
        // Row 3
        8: BluetoothCommand(upperWheelSpeed: 50, lowerWheelSpeed: 50, pitchAngle: 50, yawAngle: 20, feedSpeed: 40, controlBit: 1),
        9: BluetoothCommand(upperWheelSpeed: 50, lowerWheelSpeed: 50, pitchAngle: 50, yawAngle: 40, feedSpeed: 40, controlBit: 1),
        10: BluetoothCommand(upperWheelSpeed: 50, lowerWheelSpeed: 50, pitchAngle: 50, yawAngle: 60, feedSpeed: 40, controlBit: 1),
        11: BluetoothCommand(upperWheelSpeed: 50, lowerWheelSpeed: 50, pitchAngle: 50, yawAngle: 80, feedSpeed: 40, controlBit: 1),
        
        // Row 4 (front court)
        12: BluetoothCommand(upperWheelSpeed: 40, lowerWheelSpeed: 40, pitchAngle: 60, yawAngle: 20, feedSpeed: 30, controlBit: 1),
        13: BluetoothCommand(upperWheelSpeed: 40, lowerWheelSpeed: 40, pitchAngle: 60, yawAngle: 40, feedSpeed: 30, controlBit: 1),
        14: BluetoothCommand(upperWheelSpeed: 40, lowerWheelSpeed: 40, pitchAngle: 60, yawAngle: 60, feedSpeed: 30, controlBit: 1),
        15: BluetoothCommand(upperWheelSpeed: 40, lowerWheelSpeed: 40, pitchAngle: 60, yawAngle: 80, feedSpeed: 30, controlBit: 1)
    ]

    /// Given a position (in meters), return the matching command.
    /// If position is outside court area, return fallback.
    static func command(for position: CGPoint) -> BluetoothCommand {
        guard let zoneID = zoneID(for: position) else {
            return fallbackCommand
        }
        return hardcodedCommands[zoneID] ?? fallbackCommand
    }

    /// Compute zone ID based on player position in meters.
    /// Court size: 8.23m (width) x 5.49m (length)
    /// Zones: 4 columns x 4 rows = 16 zones
    public static func zoneID(for point: CGPoint) -> Int? {
        let courtWidth: CGFloat = 8.23
        let courtHeight: CGFloat = 5.49
        let cols = 4
        let rows = 4
        let zoneWidth = courtWidth / CGFloat(cols)
        let zoneHeight = courtHeight / CGFloat(rows)

        // Determine which column and row the point falls into
        let col = Int(point.x / zoneWidth)
        let row = Int(point.y / zoneHeight)

        // Check bounds (ensure point is on court)
        guard (0..<cols).contains(col), (0..<rows).contains(row) else {
            print("❌ Point \(point) is out of bounds")
            return nil
        }

        let zoneID = row * cols + col
        print("📍 Point \(point) mapped to zone \(zoneID) (col: \(col), row: \(row))")
        return zoneID
    }
    
    // Simple CRC calculation (XOR of all bytes)
    static func calculateCRC(_ bytes: [UInt8]) -> UInt8 {
        var crc: UInt8 = 0
        for byte in bytes {
            crc ^= byte
        }
        return crc
    }
}
