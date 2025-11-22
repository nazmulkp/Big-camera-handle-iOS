import SwiftUI
import AVFoundation

// MARK: - Root camera view

struct CameraRootView: View {
    @AppStorage("isZenMode") private var isZenMode: Bool = false
    @State private var zenHUDExpanded: Bool = false
    @AppStorage("isLeftHandedLayout") private var isLeftHandedLayout: Bool = false
    
    @StateObject private var controller = CameraController()
    @State private var showLastCapture = false
    @State private var focusPoint: CGPoint? = nil
    @State private var showFocusReticle: Bool = false
    @State private var meterMode: MeterMode = .histogram
    @State private var showProControlsSheet = false

    var body: some View {
        ZStack {
            previewLayer

            // Main HUD layout with proper spacing
            VStack(spacing: 0) {
                // Top bar with safe area consideration
                if !isZenMode || zenHUDExpanded {
                    TopInfoBarView(controller: controller)
                        .padding(.top, 8) // Reduced top padding
                }

                Spacer()

                // Bottom controls
                if isZenMode && !zenHUDExpanded {
                    ZenBottomBarView(controller: controller)
                } else {
                    MinimalBottomControlsView(
                        controller: controller,
                        showLastCapture: $showLastCapture,
                        openProControls: { showProControlsSheet = true },
                        isLeftHandedLayout: $isLeftHandedLayout
                    )
                }
            }

            // Side elements with proper positioning
            if !isZenMode || zenHUDExpanded {
                HStack {
                    if isLeftHandedLayout {
                        // Left side elements
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            QuickActionsView(controller: controller)
                             .padding(.leading, 16)
                            if controller.mode != .photo {
                                AudioLevelMetersView(controller: controller)
                                    //.padding(.top, 8)
                            }
                        }
                   
                        .padding(.bottom, 180) // Increased to avoid bottom bar overlap

                        Spacer()
                    } else {
                        Spacer()

                        // Right side elements
                        VStack(alignment: .trailing, spacing: 12) {
                            Spacer()
                            QuickActionsView(controller: controller)
                                .padding(.trailing, 16)
                            if controller.mode != .photo{
                                AudioLevelMetersView(controller: controller)
                                   /// .padding(.top, 8)
                            }
                        }
                       // .padding(.trailing, 4)
                        .padding(.bottom, 180) // Increased to avoid bottom bar overlap
                    }
                }
            }

            // Monitoring HUD with proper positioning
            if !isZenMode || zenHUDExpanded {
                HStack {
                    if isLeftHandedLayout {
                        Spacer()
                        // Monitoring HUD on right for left-handed layout
                        VStack {
                            Spacer()
                            SmallMonitoringHUD(mode: meterMode, bins: controller.histogramBins)
                                .padding(.trailing, 16)
                                .padding(.bottom, 180) // Match side elements
                        }
                    } else {
                        // Monitoring HUD on left for right-handed layout
                        VStack {
                            Spacer()
                            SmallMonitoringHUD(mode: meterMode, bins: controller.histogramBins)
                                .padding(.leading, 16)
                                .padding(.bottom, 180) // Match side elements
                        }
                        Spacer()
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isZenMode else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                zenHUDExpanded.toggle()
            }
            if zenHUDExpanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        zenHUDExpanded = false
                    }
                }
            }
        }
        .sheet(isPresented: $showProControlsSheet) {
            ProControlsSheet(
                controller: controller,
                meterMode: $meterMode,
                isLeftHandedLayout: $isLeftHandedLayout,
                isZenMode: $isZenMode
            )
        }
        .sheet(isPresented: $showLastCapture) {
            if let image = controller.lastCapturedImage {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                }
            } else {
                Text("No recent capture")
                    .padding()
            }
        }
        .onAppear {
            controller.startSession()
            controller.applyExposureSettings()
            controller.applyEVSettings()
            controller.applyWhiteBalanceSettings()
            controller.applyFocusSettings()
            controller.applyZoomSettings()
            controller.applyVideoConfiguration()
        }
        .onDisappear {
            controller.stopSession()
        }
    }

    // MARK: - Preview layer with tap-to-focus
    private var previewLayer: some View {
        GeometryReader { geo in
            ZStack {
                CameraPreviewView(controller: controller)
                    .ignoresSafeArea()

                // Timer countdown overlay (center)
                if controller.countdownRemaining > 0 {
                    Text("\(controller.countdownRemaining)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 10)
                }
                
                // Gradient overlays with proper positioning
                VStack(spacing: 0) {
                    // Top gradient
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120) // Fixed height for top gradient
                    
                    Spacer()
                    
                    // Bottom gradient
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200) // Fixed height for bottom gradient
                }
                .ignoresSafeArea()
                
                // Grid overlay
                if controller.isGridEnabled {
                    GridOverlayView()
                        .allowsHitTesting(false)
                }

                // Focus peaking overlay when in MF
                if controller.focusMode == .manual {
                    FocusPeakingOverlayView()
                }

                // Tap-to-focus / expose area
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let location = value.location
                                focusPoint = location
                                showFocusReticle = true

                                controller.focusAndExpose(
                                    at: location,
                                    viewSize: geo.size
                                )

                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        showFocusReticle = false
                                    }
                                }
                            }
                    )

                // Focus reticle
                if let point = focusPoint, showFocusReticle {
                    FocusReticleView()
                        .position(point)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showFocusReticle)
                }
            }
        }
    }
}

// MARK: - Updated Minimal Bottom Controls with better spacing
struct MinimalBottomControlsView: View {
    @ObservedObject var controller: CameraController
    @Binding var showLastCapture: Bool
    var openProControls: () -> Void
    @Binding var isLeftHandedLayout: Bool

    var body: some View {
        VStack(spacing: 12) { // Increased spacing
            statusAndReadoutsRow
            ZoomControlBar(controller: controller)
            shutterRow
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24) // Increased bottom padding
        .background(
            Color.black.opacity(0.4) // Slightly more opaque
                .blur(radius: 20)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var statusAndReadoutsRow: some View {
        HStack(spacing: 12) { // Increased spacing
            // Status indicator
            
            let (statusColor, statusText): (Color, String) = {
                if controller.mode == .video && controller.isRecording {
                    return (.red, "REC \(controller.recordingDurationString())")
                } else if controller.isSessionRunning {
                    return (.green, controller.mode == .video ? "Video Ready" : "Ready")
                } else {
                    return (.yellow, "Starting…")
                }
            }()

            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.9))
            }

//            Spacer()
//
//            // Photo / Video toggle
//            Picker("", selection: $mode) {
//                Text("Photo").tag(CaptureMode.photo)
//                Text("Video").tag(CaptureMode.video)
//            }
//            .pickerStyle(.segmented)
//            .frame(width: 140) // Slightly wider
//
//            Spacer()

            // Right-side readout
            Text(readoutLine)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: true, vertical: false) // Prevent text compression
        }
    }

    private var readoutLine: String {
        if controller.mode == .photo {
            let ss  = controller.shutterReadoutShort()
            let ev  = controller.evReadoutShort()
            let iso = controller.isoReadoutShort()
            return "\(ss) • \(ev) • \(iso)"
        } else {
            return controller.videoStatusSummary()
        }
    }

    private var shutterRow: some View {
        HStack(spacing: 0) { // Increased spacing
            if isLeftHandedLayout {
                shutterButton
                    .padding(.leading,20)
                    .disabled(controller.mode == .photo)
                takePhoto
                    .padding(.horizontal,22)
                switchCamera
                    .padding(.horizontal,22)
                Spacer()
                
                proControlsButton
                    .padding(.horizontal,22)
                lastThumbnailButton
            } else {
                
                proControlsButton
                // Camera switch button (front/back)
                takePhoto
                    .padding(.leading,22)
                Spacer()
                shutterButton
                    .disabled(controller.mode == .photo)
                Spacer()
                switchCamera
                    .padding(.trailing,22)
                lastThumbnailButton
            }
        }
    }
    
    
    private var takePhoto:some View {
        // More prominent quick photo button
        Button {
            if !controller.isRecording {
                controller.mode = .photo
                
                controller.triggerPhotoCapture()
            }
        } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(controller.isRecording ? .gray : .white)
                .frame(width: 44, height: 44)
                .background(controller.isRecording ? .black.opacity(0.3) : .blue)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(controller.isRecording ? .gray : .blue, lineWidth: 2)
                )
        }
        .disabled(controller.isRecording)
    }
    
    private var switchCamera:some View {
        Button {
            if !controller.isRecording {
                controller.switchCamera()
            }
        } label: {
            Image(systemName: "camera.rotate")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(controller.isRecording ? .gray : .white)
                .frame(width: 44, height: 44)
                .background(controller.isRecording ? .black.opacity(0.3) : .purple)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(controller.isRecording ? .gray : .purple, lineWidth: 2)
                )
        }
        .disabled(controller.isRecording)
    }
    

    private var shutterButton: some View {
        Button {
            switch controller.mode {
            case .photo:
                controller.triggerPhotoCapture()
            case .video:
                if controller.isRecording {
                    controller.stopRecording()
                } else {
                    controller.startRecording()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(0.9), lineWidth: 4)
                    .frame(width: 80, height: 80)

                if controller.mode == .photo {
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                } else {
                    if controller.isRecording {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.red)
                            .frame(width: 32, height: 32)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.red)
                            .frame(width: 42, height: 42)
                    }
                }
            }
        }
    }

    private var proControlsButton: some View {
        Button {
            openProControls()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.5))
                .clipShape(Circle())
        }
    }

    private var lastThumbnailButton: some View {
        Button {
            if controller.lastCapturedImage != nil {
                showLastCapture = true
            }
        } label: {
            Group {
                if let img = controller.lastCapturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(width: 52, height: 52)
            .background(.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Updated Quick Actions with better spacing
struct QuickActionsView: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(spacing: 16) { // Increased spacing
            // Flash
            Button {
                controller.cycleFlashMode(isVideo: controller.mode == .video)
            } label: {
                QuickActionIcon(
                    systemImage: controller.flashModeState.iconName,
                    isActive: controller.flashModeState != .off,
                    text: controller.flashModeState.label
                )
            }

            // Timer
            Button {
                controller.cycleTimerMode()
            } label: {
                QuickActionIcon(
                    systemImage: "timer",
                    isActive: controller.captureTimerSeconds > 0,
                    text: timerLabel
                )
            }

            // Grid
            Button {
                controller.toggleGrid()
            } label: {
                QuickActionIcon(
                    systemImage: "square.grid.3x3",
                    isActive: controller.isGridEnabled,
                    text: "Grid"
                )
            }

            // AE/AF Lock
            Button {
                controller.toggleAEAFLock()
            } label: {
                QuickActionIcon(
                    systemImage: controller.isAEAFLocked ? "lock.fill" : "lock.open",
                    isActive: controller.isAEAFLocked,
                    text: "Lock"
                )
            }
        }
    }

    private var timerLabel: String {
        switch controller.captureTimerSeconds {
        case 3:  return "3s"
        case 10: return "10s"
        default: return "Off"
        }
    }
}

// MARK: - Updated Audio Meters with better sizing
struct AudioLevelMetersView: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(spacing: 8) {
            AudioMeterBar(
                level: controller.audioLevelLeft,
                peakLevel: controller.audioPeakLeft,
                db: controller.audioDBLeft,
                label: "L"
            )
            AudioMeterBar(
                level: controller.audioLevelRight,
                peakLevel: controller.audioPeakRight,
                db: controller.audioDBRight,
                label: "R"
            )
        }
        .padding(4)
        .background(Color.black.opacity(0.5)) // More opaque
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(width: 80) // Fixed width for consistency
    }
}

// MARK: - Updated Small Monitoring HUD
struct SmallMonitoringHUD: View {
    let mode: MeterMode
    let bins: [CGFloat]

    var body: some View {
        MonitoringHUDView(mode: mode, bins: bins)
            .frame(width: 140, height: 60)
            .allowsHitTesting(false)
    }
}

// MARK: - Updated Zen Bottom Bar
struct ZenBottomBarView: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(spacing: 12) { // Increased spacing
            // Tiny exposure / video readout
            Text(readoutLine)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 8)

            // Same zoom bar as full mode
            ZoomControlBar(controller: controller)

            // Big shutter, centered
            Button {
                switch controller.mode {
                case .photo:
                    controller.triggerPhotoCapture()
                case .video:
                    if controller.isRecording {
                        controller.stopRecording()
                    } else {
                        controller.startRecording()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.white.opacity(0.9), lineWidth: 4)
                        .frame(width: 80, height: 80)

                    if controller.mode == .photo {
                        Circle()
                            .fill(.white)
                            .frame(width: 64, height: 64)
                    } else {
                        if controller.isRecording {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.red)
                                .frame(width: 32, height: 32)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.red)
                                .frame(width: 42, height: 42)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24) // Increased bottom padding
        .background(
            Color.black.opacity(0.3)
                .blur(radius: 20)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var readoutLine: String {
        if controller.mode == .photo {
            let ss  = controller.shutterReadoutShort()
            let ev  = controller.evReadoutShort()
            let iso = controller.isoReadoutShort()
            return "\(ss) • \(ev) EV • ISO \(iso)"
        } else {
            return controller.videoStatusSummary()
        }
    }
}
