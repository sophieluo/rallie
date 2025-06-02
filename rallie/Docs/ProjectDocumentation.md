# Rallie iOS App - Comprehensive Project Documentation

## 1. Project Overview

Rallie is an innovative iOS application that powers an AI-driven tennis ball machine. The app uses computer vision to track a player's position on a tennis court in real-time, maps this position to court coordinates, and sends commands via Bluetooth to dynamically adjust shot placement based on the player's movement. This creates an interactive training experience that adapts to the player, simulating aspects of training with a human coach.

## 2. Product Vision

The ultimate goal of Rallie is to leverage AI technologies such as Computer Vision and NLP to deliver an immersive, intelligent solo training experience that mirrors the feedback and adaptability of a human coach. The system follows a Vision-Language-Action model, with Vision and Language processing on the iPhone and Action execution on the ball machine.

Beyond controlling the ball machine, Rallie aims to function as a "virtual coach," offering personalized training plans, post-training feedback, and strategic insights. It can also serve as a "line judge," providing automated line calls during match play.

## 3. Development Phases

### Phase 1 - Demo & MVP (Current Phase)
**Focus:** Core perception-action loop  
**Goal:** Demonstrate end-to-end adaptive training using vision and simple rules

**Core Features:**
- Courtline detection
- Manual court alignment
- Homography matrix calculation
- Real-time person detection and foot position tracking
- Simple rule-based module engine for command generation
- BLE command sending via hardcoded UUIDs

**Status:**
- Most core features built natively in iOS
- Needs refinement, cleanup, and bug fixes

**Tasks:**
- **Required:**
  1. Fix bugs in person detection for accurate player position
  2. Complete the perception → action (BLE command) module
  3. Refactor and clean code
- **Optional:**
  1. Improve calibration/alignment UX (e.g., auto-alignment using Vision line detection)
  2. Allow users to select different skill levels for ball speed and interval

### Phase 2 - Advanced Features (Subject to change)
**Focus:** Integrate advanced CV/AI and polish user experience

**Key Features:**
1. LLM integration for training plans
2. Player pose detection and tennis ball tracking
3. Hybrid reasoning module (rule-based + LLM)
4. Highlight clip feature (optional)
5. Optimization for latency and battery life

### Phase 3 - Production Ready (Subject to change)
**Focus:** Custom model development and deployment pipeline

**Goals:**
- Train and integrate optimized CV models
- Enable efficient, on-device inference
- Add production-level app infrastructure (user accounts, etc.)

## 4. System Architecture

### Core Components

1. **Vision System**
   - Uses Apple's Vision framework for real-time player detection
   - Tracks player's foot position with confidence thresholds
   - Processes camera frames in landscape orientation

2. **Court Mapping System**
   - Implements homography transformation to map camera view to real-world court coordinates
   - Uses OpenCV for matrix calculations (via Objective-C++ wrapper)
   - Visualizes court overlay with projected lines

3. **Command System**
   - Divides court into 16 zones (4×4 grid)
   - Maps player positions to pre-tuned 18-digit commands
   - Buffers positions and sends commands at 3-second intervals

4. **Bluetooth Communication**
   - Manages connection to the ball machine
   - Transmits commands in UTF-8 format
   - Handles device discovery and connection management

## 5. User Flows

### 5.1 Setup Flow
1. User places iPhone on a tripod facing the court
2. Opens app → taps "Interactive Mode" → camera preview launches
3. Aligns the projected trapezoid overlay with the court corners → taps "Aligned – Let's Go!"
   - If needed, manually drag corners to align
   - (Optional) Enable auto-alignment via Vision framework line detection
4. Begin real-time player detection

### 5.2 Training Session Flow
1. Player moves on court
2. Player detection tracks and outputs player coordinates every n frames
3. System averages previous data points and maps player position to the minicourt view
4. Logic manager determines which zone the user is in
5. Command is looked up and sent via Bluetooth
6. Ball is launched accordingly

## 6. Key Features Implementation Status

### 6.1 Player Detection
- **Status:** Integrated but buggy
- Uses Apple Vision to detect ankles
- Projects player foot position onto the mini-court via homography
- **Implementation:** PlayerDetector.swift uses VNDetectHumanBodyPoseRequest with confidence thresholds

### 6.2 Court Alignment
- **Status:** Hardcoded trapezoid done; draggable version ~50% complete
- User aligns trapezoid with court lines
- Calculates homography matrix for coordinate mapping
- **Implementation:** HomographyHelper.swift and CourtLayout.swift handle the mapping

### 6.3 Zone Mapping
- **Status:** Logic implemented, not fully tested
- Divides near side of court into 16 zones (4x4)
- Averages last n positions to determine zone
- **Implementation:** CommandLookup.swift handles zone identification

### 6.4 Command Engine
- **Status:** Functional but untested
- Uses lookup table of 18-digit commands mapped to zones
- Sends command every 3 seconds via LogicManager
- **Implementation:** LogicManager.swift buffers positions and triggers commands

### 6.5 Bluetooth Communication
- **Status:** Placeholders written, not tested
- Sends command via BLE using hardcoded UUID
- Needs error handling for disconnection / UUID fallback
- **Implementation:** BluetoothManager.swift handles BLE communication

### 6.6 Homography Tap Validation (Dev Mode)
- **Status:** Previously working, currently buggy after draggable corners integration
- User taps screen → mini-court should show mapped location
- Used for testing and validation of homography math
- **Implementation:** CameraController.swift handles tap processing
- **Known Issue:** After recent integration of draggable corners feature, the mapping is incorrect (e.g., tapping upper left shows dot in upper right corner of minicourtview)
- **Fix Priority:** High - needs to be addressed for accurate debugging and testing

## 7. Technical Details

### Key Files and Their Responsibilities

#### Controllers
- **CameraController.swift**
  - Manages camera setup and configuration
  - Processes video frames and detects player position
  - Computes court homography and projects court lines
  - Handles user taps and logging

- **LogicManager.swift**
  - Buffers player positions with timestamps
  - Calculates average position over the last second
  - Maps positions to zones and retrieves appropriate commands
  - Ensures commands are sent at appropriate intervals (every 3 seconds)

- **BluetoothManager.swift**
  - Handles BLE device discovery and connection
  - Manages service and characteristic discovery
  - Transmits commands to the connected ball machine

#### Vision
- **PlayerDetector.swift**
  - Implements body pose detection using VNDetectHumanBodyPoseRequest
  - Tracks ankle positions with confidence thresholds
  - Converts Vision coordinates to pixel coordinates

#### Utils
- **HomographyHelper.swift**
  - Computes homography matrix using OpenCV
  - Projects points from image space to court space
  - Validates points are within the court trapezoid

- **CommandLookup.swift**
  - Maps court zones to specific 18-digit commands
  - Provides fallback commands for out-of-bounds positions
  - Divides court into 4×4 grid for zone identification

- **CourtLayout.swift**
  - Defines real-world court dimensions (11.885m × 8.23m half-court)
  - Provides reference points for homography calculation
  - Calculates screen positions for court overlay

#### Views
- **CameraView.swift**
  - Main interactive camera screen
  - Displays camera feed with overlays
  - Handles user interaction

- **OverlayShapeView.swift**
  - Displays alignment trapezoid for setup
  - Helps users position the camera correctly

- **MiniCourtView.swift**
  - Visualizes player position on a miniature court
  - Shows tap positions for debugging

### Court Dimensions
- Half court: 11.885m (baseline to net) × 8.23m wide
- Service line: 6.40m from net
- Coordinate system: (0,0) at net's left corner

### Command Format
Each command is an 18-digit string with the format:
```
[00000] upper motor speed
[00000] lower motor speed
[0000]  pitch angle
[0000]  yaw angle
```

## 8. Technical Requirements

- **Platform:** iOS (SwiftUI + Vision framework + CoreML + OpenCV)
- **Camera:** Rear-facing, landscape orientation
- **Data Transfer:** Bluetooth LE
- **Model Inference:** CoreML or TFLite (future phases)
- **Device Support:** iPhone 12 and above
- **Performance:**
  - Sub-100ms latency from player detection to command dispatch
  - Battery-safe and camera-heat safe under 1-hour use
  - Offline-first, no need for internet during training

## 9. Current Challenges and Next Steps

### Immediate Priorities
1. Fix bugs in person detection to improve accuracy
2. Complete and test the perception → action loop
3. Refactor code for better maintainability

### Future Enhancements
1. Improve court alignment UX with auto-detection
2. Add skill level selection for customized ball delivery (modify LogicManager logics)
3. Prepare for Phase 2 integration of advanced AI features

## 10. Debugging Tools

- CSV logging of player positions to `Documents/player_positions.csv`
- Mini court visualization for real-time position feedback
- Console logging with emoji indicators for easy identification

---

*Last updated: June 2, 2025*