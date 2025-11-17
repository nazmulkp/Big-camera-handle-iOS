import SwiftUI
import AVFoundation

// MARK: - Capture + Monitoring modes

enum CaptureMode {
    case photo
    case video
}

enum MeterMode: String, CaseIterable, Identifiable {
    case histogram
    case waveform

    var id: String { rawValue }

    var label: String {
        switch self {
        case .histogram: return "Histogram"
        case .waveform:  return "Waveform"
        }
    }
}

// MARK: - Root camera view

struct CameraRootView: View {
    @StateObject private var controller = CameraController()
    @State private var mode: CaptureMode = .photo
    @State private var showLastCapture = false

    // Focus UI state (tap reticle)
    @State private var focusPoint: CGPoint? = nil
    @State private var showFocusReticle: Bool = false

    // Monitoring HUD
    @State private var meterMode: MeterMode = .histogram

    // Pro controls sheet
    @State private var showProControlsSheet = false

    var body: some View {
        ZStack {
            previewLayer

            // HUD overlays
            VStack(spacing: 0) {
                TopInfoBarView(controller: controller)

                Spacer()

                MinimalBottomControlsView(
                    controller: controller,
                    mode: $mode,
                    showLastCapture: $showLastCapture,
                    openProControls: { showProControlsSheet = true }
                )
            }

            // Right-side quick actions (flash / timer / grid / lock)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    QuickActionsView(controller: controller, mode: $mode)
                        .padding(.bottom, 140)
                        .padding(.trailing, 12)
                }
            }
            
            // Audio meters on the right in Video mode
            if mode == .video {
                HStack {
                    Spacer()
                    AudioLevelMetersView(controller: controller)
                        .padding(.trailing, 8)
                        .padding(.bottom, 140)   // keep clear of bottom controls
                }
            }

            // Small histogram/waveform HUD in lower-left corner
            VStack {
                Spacer()
                HStack {
                    SmallMonitoringHUD(
                        mode: meterMode,
                        bins: controller.histogramBins
                    )
                    .padding(.leading, 12)
                    .padding(.bottom, 140)

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showProControlsSheet) {
            ProControlsSheet(
                controller: controller,
                meterMode: $meterMode
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

            // 👇 add this
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
                CameraPreviewView(session: controller.session)
                    .ignoresSafeArea()

                // Timer countdown overlay (center)
                if controller.countdownRemaining > 0 {
                    Text("\(controller.countdownRemaining)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 10)
                }
                
                // Gradient to make HUD readable
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.7),
                        Color.clear,
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
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
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7),
                            value: showFocusReticle
                        )
                }
            }
        }
    }
}

// MARK: - Top Info Bar

struct TopInfoBarView: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        HStack {
            Button {
                // Settings hook
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.4))
                    .clipShape(Circle())
            }

            Spacer()

            Text(infoText)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.black.opacity(0.4))
                .clipShape(Capsule())

            Spacer()

            Button {
                // Share / connect hook
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.4))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var infoText: String {
        let focal  = controller.focalLengthReadout()
        let format = controller.photoFormat.shortLabel
        let ss     = controller.shutterReadoutShort()
        let ev     = controller.evReadoutShort()
        let iso    = controller.isoReadoutShort()

        return "\(focal) • \(format) • \(ss) SS • \(ev) EV • \(iso) ISO"
    }
}

// MARK: - Quick Actions (right side)

struct QuickActionsView: View {
    @ObservedObject var controller: CameraController
    @Binding var mode: CaptureMode

    var body: some View {
        VStack(spacing: 10) {
            // Flash
            Button {
                controller.cycleFlashMode(isVideo: mode == .video)
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

struct QuickActionIcon: View {
    let systemImage: String
    let isActive: Bool
    let text: String?

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isActive ? Color.yellow : Color.white)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            Circle()
                                .stroke(
                                    isActive ? Color.yellow.opacity(0.8)
                                             : Color.white.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )

            if let text {
                Text(text)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .buttonStyle(.plain)
    }
}


struct QuickActionButton: View {
    let icon: String
    var body: some View {
        Button {
            // hook up later
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(8)
                .background(.black.opacity(0.45))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Minimal bottom controls (status + zoom + shutter row)

struct MinimalBottomControlsView: View {
    @ObservedObject var controller: CameraController
    @Binding var mode: CaptureMode
    @Binding var showLastCapture: Bool
    var openProControls: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            statusAndReadoutsRow
            ZoomControlBar(controller: controller)
            shutterRow
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .background(
            Color.black.opacity(0.35)
                .blur(radius: 20)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var statusAndReadoutsRow: some View {
        HStack(spacing: 8) {
            // Status dot + text
            let (statusColor, statusText): (Color, String) = {
                if mode == .video && controller.isRecording {
                    return (.red, "REC \(controller.recordingDurationString())")
                } else if controller.isSessionRunning {
                    return (.green, mode == .video ? "Video Ready" : "Ready")
                } else {
                    return (.yellow, "Starting…")
                }
            }()

            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))

            Spacer(minLength: 8)

            // Photo / Video toggle (unchanged)
            Picker("", selection: $mode) {
                Text("Photo").tag(CaptureMode.photo)
                Text("Video").tag(CaptureMode.video)
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
            .onChange(of: mode) { newMode in
                if newMode == .video {
                    controller.applyVideoConfiguration()
                }
            }

            Spacer(minLength: 8)

            // Right-side readout
            Text(readoutLine)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
        }
    }


    private var readoutLine: String {
           if mode == .photo {
               let ss  = controller.shutterReadoutShort()
               let ev  = controller.evReadoutShort()
               let iso = controller.isoReadoutShort()
               return "\(ss) SS   \(ev) EV   \(iso) ISO"
           } else {
               // Video summary: 4K • 30 fps • HEVC
               return controller.videoStatusSummary()
           }
       }

    private var shutterRow: some View {
        HStack(spacing: 24) {
            // Pro controls button
            Button {
                openProControls()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.5))
                    .clipShape(Circle())
            }

            Spacer()

            // Shutter (photo / video)
            Button {
                switch mode {
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

                    if mode == .photo {
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

            Spacer()

            // Last thumbnail
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
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}

// MARK: - Zoom control bar

struct ZoomControlBar: View {
    @ObservedObject var controller: CameraController

    // “native” presets we’ll try to hit
    private let ultraWideZoom: CGFloat = 0.5
    private let wideZoom:      CGFloat = 1.0
    private let teleZoom:      CGFloat = 2.0

    var body: some View {
        HStack(spacing: 12) {
            // Preset buttons
            ZoomPresetButton(
                label: "0.5x",
                isSelected: controller.zoomFactor < 0.75,
                action: { controller.setZoomPreset(ultraWideZoom) }
            )

            ZoomPresetButton(
                label: "1x",
                isSelected: controller.zoomFactor >= 0.75 && controller.zoomFactor < 1.5,
                action: { controller.setZoomPreset(wideZoom) }
            )

            ZoomPresetButton(
                label: "2x",
                isSelected: controller.zoomFactor >= 1.5 && controller.zoomFactor < 2.5,
                action: { controller.setZoomPreset(teleZoom) }
            )

            // Continuous zoom slider
            Slider(
                value: Binding(
                    get: { controller.zoomSliderValue },
                    set: { controller.updateZoomSlider($0) }
                ),
                in: 0...1
            )
            .tint(.white)
        }
        .font(.caption)
    }
}

struct ZoomPresetButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.white.opacity(0.9)
                                         : Color.white.opacity(0.15))
                )
                .foregroundStyle(isSelected ? .black : .white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small Monitoring HUD in corner

struct SmallMonitoringHUD: View {
    let mode: MeterMode
    let bins: [CGFloat]

    var body: some View {
        MonitoringHUDView(mode: mode, bins: bins)
            .frame(width: 140, height: 60)
    }
}

// MARK: - Pro Controls Sheet (all “deep” controls live here)

struct ProControlsSheet: View {
    @ObservedObject var controller: CameraController
    @Binding var meterMode: MeterMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ExposureSection(controller: controller)
                    FocusSection(controller: controller)
                    WhiteBalanceSection(controller: controller)
                    FormatSection(controller: controller)
                    VideoSection(controller: controller)               // 👈 NEW
                    MonitoringSection(controller: controller, meterMode: $meterMode)
                }
                .padding()
            }
            .navigationTitle("Pro Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Section helpers

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
    }
}

/// Reusable slider row used for Shutter, ISO, EV, Focus, Temp, Tint, Auto ISO
struct SettingSliderRow: View {
    let title: String
    @Binding var value: Double
    var enabled: Bool

    init(title: String, value: Binding<Double>, enabled: Bool = true) {
        self.title = title
        self._value = value
        self.enabled = enabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))

            Slider(value: $value, in: 0...1)
                .disabled(!enabled)
                .opacity(enabled ? 1.0 : 0.4)
        }
    }
}

// MARK: - Exposure section

struct ExposureSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Exposure")

            Picker(
                "Exposure Mode",
                selection: Binding(
                    get: { controller.exposureMode },
                    set: { controller.setExposureMode($0) }
                )
            ) {
                ForEach(ExposureControlMode.allCases) { mode in
                    Text(mode.shortLabel).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Shutter / ISO
            HStack(spacing: 12) {
                SettingSliderRow(
                    title: "Shutter",
                    value: Binding(
                        get: { controller.shutterSliderValue },
                        set: { controller.updateShutterSlider($0) }
                    ),
                    enabled: !(controller.exposureMode == .auto ||
                               controller.exposureMode == .isoPriority)
                )

                SettingSliderRow(
                    title: "ISO",
                    value: Binding(
                        get: { controller.isoSliderValue },
                        set: { controller.updateISOSlider($0) }
                    ),
                    enabled: !(controller.exposureMode == .auto ||
                               controller.exposureMode == .shutterPriority)
                )
            }

            // EV
            SettingSliderRow(
                title: "EV Compensation",
                value: Binding(
                    get: { controller.evSliderValue },
                    set: { controller.updateEVSlider($0) }
                ),
                enabled: true
            )

            Text(controller.evDisplayString())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))

            // Auto ISO min/max
            HStack(spacing: 12) {
                SettingSliderRow(
                    title: "Auto ISO Min",
                    value: Binding(
                        get: { controller.autoISOMinSliderValue },
                        set: { controller.updateAutoISOMinSlider($0) }
                    ),
                    enabled: true
                )

                SettingSliderRow(
                    title: "Auto ISO Max",
                    value: Binding(
                        get: { controller.autoISOMaxSliderValue },
                        set: { controller.updateAutoISOMaxSlider($0) }
                    ),
                    enabled: true
                )
            }

            Text(controller.autoISORangeDisplayString())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 6) {
                Text(controller.shutterDisplayString())
                Text("•")
                Text(controller.isoDisplayString())
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - Focus section

struct FocusSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Focus")

            Picker(
                "Focus Mode",
                selection: Binding(
                    get: { controller.focusMode },
                    set: { controller.setFocusMode($0) }
                )
            ) {
                ForEach(FocusControlMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            SettingSliderRow(
                title: "Manual Focus",
                value: Binding(
                    get: { controller.focusSliderValue },
                    set: { controller.updateFocusSlider($0) }
                ),
                enabled: controller.focusMode == .manual
            )

            Text(controller.focusDisplayString())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - White balance section

struct WhiteBalanceSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "White Balance")

            Picker(
                "White Balance",
                selection: Binding(
                    get: { controller.whiteBalanceMode },
                    set: { controller.setWhiteBalanceMode($0) }
                )
            ) {
                ForEach(WhiteBalanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                SettingSliderRow(
                    title: "Temp",
                    value: Binding(
                        get: { controller.tempSliderValue },
                        set: { controller.updateTemperatureSlider($0) }
                    ),
                    enabled: controller.whiteBalanceMode == .manual
                )

                SettingSliderRow(
                    title: "Tint",
                    value: Binding(
                        get: { controller.tintSliderValue },
                        set: { controller.updateTintSlider($0) }
                    ),
                    enabled: controller.whiteBalanceMode == .manual
                )
            }

            if controller.whiteBalanceMode == .manual {
                HStack(spacing: 8) {
                    ForEach(WhiteBalancePreset.allCases) { preset in
                        Button {
                            controller.applyWhiteBalancePreset(preset)
                        } label: {
                            Text(preset.label)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Text(controller.whiteBalanceDisplayString())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Format section

struct FormatSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Format")

            Picker(
                "Photo Format",
                selection: Binding(
                    get: { controller.photoFormat },
                    set: { newValue in
                        switch newValue {
                        case .heif where !controller.supportsHEIF: return
                        case .raw where !controller.supportsRAW: return
                        case .proRAW where !controller.supportsProRAW: return
                        default:
                            controller.photoFormat = newValue
                        }
                    })
            ) {
                ForEach(PhotoFormat.allCases) { format in
                    let supported: Bool = {
                        switch format {
                        case .jpeg:   return true
                        case .heif:   return controller.supportsHEIF
                        case .raw:    return controller.supportsRAW
                        case .proRAW: return controller.supportsProRAW
                        }
                    }()

                    HStack {
                        Text(format.shortLabel)
                        if !supported {
                            Text("∙ N/A")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .tag(format)
                }
            }
            .pickerStyle(.segmented)

            Text(formatDescription(for: controller.photoFormat))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func formatDescription(for format: PhotoFormat) -> String {
        switch format {
        case .jpeg:
            return "JPEG • Maximum compatibility."
        case .heif:
            return "HEIF • Smaller files, high quality."
        case .raw:
            return "RAW • Maximum dynamic range for editing."
        case .proRAW:
            return "ProRAW-style RAW capture (device dependent)."
        }
    }
}

// MARK: - Monitoring section

struct MonitoringSection: View {
    @ObservedObject var controller: CameraController
    @Binding var meterMode: MeterMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Monitoring")

            Picker("Monitoring Mode", selection: $meterMode) {
                ForEach(MeterMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            MonitoringHUDView(
                mode: meterMode,
                bins: controller.histogramBins
            )
            .frame(height: 60)
        }
    }
}

// MARK: - Focus Reticle & Peaking

struct FocusReticleView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 80, height: 80)
            .shadow(color: .yellow.opacity(0.7), radius: 4)
    }
}

struct FocusPeakingOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: w / 2, y: h * 0.15))
                    path.addLine(to: CGPoint(x: w / 2, y: h * 0.85))

                    path.move(to: CGPoint(x: w * 0.15, y: h / 2))
                    path.addLine(to: CGPoint(x: w * 0.85, y: h / 2))
                }
                .stroke(Color.green.opacity(0.5), lineWidth: 1)

                Path { path in
                    let inset: CGFloat = 40

                    path.move(to: CGPoint(x: inset, y: inset + 12))
                    path.addLine(to: CGPoint(x: inset, y: inset))
                    path.addLine(to: CGPoint(x: inset + 12, y: inset))

                    path.move(to: CGPoint(x: w - inset - 12, y: inset))
                    path.addLine(to: CGPoint(x: w - inset, y: inset))
                    path.addLine(to: CGPoint(x: w - inset, y: inset + 12))

                    path.move(to: CGPoint(x: inset, y: h - inset - 12))
                    path.addLine(to: CGPoint(x: inset, y: h - inset))
                    path.addLine(to: CGPoint(x: inset + 12, y: h - inset))

                    path.move(to: CGPoint(x: w - inset - 12, y: h - inset))
                    path.addLine(to: CGPoint(x: w - inset, y: h - inset))
                    path.addLine(to: CGPoint(x: w - inset, y: h - inset - 12))
                }
                .stroke(Color.green.opacity(0.7), lineWidth: 1.0)
            }
            .blendMode(.screen)
            .opacity(0.8)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Monitoring HUD (Histogram / Waveform)

struct MonitoringHUDView: View {
    let mode: MeterMode
    let bins: [CGFloat]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            switch mode {
            case .histogram:
                HistogramView(bins: bins)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)

            case .waveform:
                WaveformView(bins: bins)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
            }
        }
    }
}

struct HistogramView: View {
    let bins: [CGFloat]

    var body: some View {
        GeometryReader { geo in
            let count = max(bins.count, 1)
            let barWidth = max(geo.size.width / CGFloat(count), 1)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    let value = bins[safe: i] ?? 0
                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(
                            width: barWidth,
                            height: max(1, value * geo.size.height)
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct WaveformView: View {
    let bins: [CGFloat]

    var body: some View {
        GeometryReader { geo in
            let count = max(bins.count, 1)
            let width = geo.size.width
            let height = geo.size.height

            let stepX = width / CGFloat(max(count - 1, 1))

            Path { path in
                for i in 0..<count {
                    let value = bins[safe: i] ?? 0
                    let x = CGFloat(i) * stepX
                    let y = (1.0 - value) * height

                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.green.opacity(0.9), lineWidth: 1.5)
            .shadow(color: .green.opacity(0.8), radius: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// Safe index helper
private extension Array where Element == CGFloat {
    subscript(safe index: Int) -> CGFloat? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

struct GridOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Path { path in
                // Vertical lines (thirds)
                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: h))

                path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * w / 3, y: h))

                // Horizontal lines (thirds)
                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))

                path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
            }
            .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
        }
    }
}

struct VideoSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Video")

            // Resolution
            Picker(
                "Resolution",
                selection: Binding(
                    get: { controller.videoResolution },
                    set: { controller.setVideoResolution($0) }
                )
            ) {
                ForEach(VideoResolution.allCases) { res in
                    Text(res.label).tag(res)
                }
            }
            .pickerStyle(.segmented)

            // FPS + Stabilization
            HStack(spacing: 12) {
                Picker(
                    "FPS",
                    selection: Binding(
                        get: { controller.videoFrameRate },
                        set: { controller.setVideoFrameRate($0) }
                    )
                ) {
                    ForEach(VideoFrameRate.allCases) { fps in
                        Text(fps.label).tag(fps)
                    }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: Binding(
                    get: { controller.videoStabilizationEnabled },
                    set: { controller.setVideoStabilizationEnabled($0) }
                )) {
                    Text("Stab")
                        .font(.caption2)
                }
                .toggleStyle(.switch)
                .labelsHidden()
            }

            // Codec
            Picker(
                "Codec",
                selection: Binding(
                    get: { controller.videoCodec },
                    set: { controller.setVideoCodec($0) }
                )
            ) {
                ForEach(VideoCodecPreset.allCases) { codec in
                    let disabled = isCodecVisuallyDisabled(codec)
                    HStack {
                        Text(codec.label)
                        if disabled {
                            Text("∙ N/A")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(disabled ? .white.opacity(0.4) : .white)
                    .tag(codec)
                }
            }
            .pickerStyle(.segmented)

            // Color profile
            Picker(
                "Color",
                selection: Binding(
                    get: { controller.videoColorProfile },
                    set: { controller.setVideoColorProfile($0) }
                )
            ) {
                ForEach(VideoColorProfile.allCases) { profile in
                    Text(profile.label).tag(profile)
                }
            }
            .pickerStyle(.segmented)

            // Bitrate (UI only)
            Picker(
                "Bitrate",
                selection: Binding(
                    get: { controller.videoBitratePreset },
                    set: { controller.setVideoBitratePreset($0) }
                )
            ) {
                ForEach(VideoBitratePreset.allCases) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            Text(videoSummary)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func isCodecVisuallyDisabled(_ codec: VideoCodecPreset) -> Bool {
        switch codec {
     
        default:
            return false
        }
    }

    private var videoSummary: String {
        let res  = controller.videoResolution.label
        let fps  = controller.videoFrameRate.label
        let stab = controller.videoStabilizationEnabled ? "Stab On" : "Stab Off"
        let codec = controller.videoCodec.label
        let color = controller.videoColorProfile.label
        let bitrate = controller.videoBitratePreset.label

        return "\(res) • \(fps) • \(stab) • \(codec) • \(color) • \(bitrate)"
    }
}


struct AudioLevelMetersView: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(spacing: 6) {
            AudioMeterBar(level: controller.audioLevelLeft, label: "L")
            AudioMeterBar(level: controller.audioLevelRight, label: "R")
        }
        .padding(6)
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AudioMeterBar: View {
    let level: CGFloat   // 0...1
    let label: String

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 8, height: 60)

                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(
                        colors: [Color.green, Color.yellow, Color.red],
                        startPoint: .bottom,
                        endPoint: .top
                    ))
                    .frame(width: 8, height: max(2, 60 * level))
                    .animation(.linear(duration: 0.08), value: level)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}


