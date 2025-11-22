//
//  CameraRootUtilView.swift
//  CameraAppSwiftUI
//
//  Created by Md Nazmul Hasan on 11/18/25.
//

import SwiftUI
import AVFoundation





// MARK: - Top Info Bar

struct TopInfoBarView: View {
    @ObservedObject var controller: CameraController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.4))
                    .clipShape(Circle())
                    .opacity(controller.isRecording ? 0.4 :1.0)
                    
            }
            .disabled(controller.isRecording)
            


            Spacer()

            Text(infoText)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.black.opacity(0.4))
                .clipShape(Capsule())

            Spacer()

//            Button {
//                // Share / connect hook
//            } label: {
//                Image(systemName: "square.and.arrow.up")
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundStyle(.white)
//                    .padding(8)
//                    .background(.black.opacity(0.4))
//                    .clipShape(Circle())
//            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var infoText: String {
        let focal = controller.focalLengthReadout()
        let battery = controller.batteryStatusSummary()
//        if controller.isRecording {
//            // Recording emphasis
//            return "\(focal) • REC \(controller.recordingDurationString())"
//        }

        if controller.videoResolution != .res1080p { // or use a `mode` binding
            // Video-style readout
            let videoSummary = controller.videoStatusSummary() // "1080p • 30 fps • HEVC"
            return "\(focal) • \(videoSummary) • \(battery)"
        }

        // Photo-style (existing)
        let format = controller.photoFormat.shortLabel
        let ss     = controller.shutterReadoutShort()
        let ev     = controller.evReadoutShort()
        let iso    = controller.isoReadoutShort()
        return "\(focal) • \(format) • \(ss) SS • \(ev) EV • \(iso) ISO • \(battery)"
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


// MARK: - Zoom control bar

// MARK: - Zoom control bar (Debug version)

struct ZoomControlBar: View {
    @ObservedObject var controller: CameraController

    // Target zoom factors we *want* for each preset
    private let ultraWideZoom: CGFloat = 0.5
    private let wideZoom: CGFloat      = 1.0
    private let teleZoom: CGFloat      = 2.0

    /// Index of the preset that is currently closest to the real zoom factor
    private var selectedPresetIndex: Int {
        let current = controller.zoomFactor
        let presets: [CGFloat] = [ultraWideZoom, wideZoom, teleZoom]

        // find the index with minimal distance to current zoom
        let (index, _) = presets
            .enumerated()
            .min(by: { abs($0.element - current) < abs($1.element - current) })
        ?? (1, wideZoom)   // default to 1x

        return index
    }

    private var isUltraWideSelected: Bool { selectedPresetIndex == 0 }
    private var isWideSelected: Bool      { selectedPresetIndex == 1 }
    private var isTeleSelected: Bool      { selectedPresetIndex == 2 }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
//                ZoomPresetButton(
//                    label: "0.5x",
//                    isSelected: isUltraWideSelected,
//                    action: {
//                        print("Setting zoom to 0.5x")
//                        controller.setZoomPreset(ultraWideZoom)
//                    }
//                )

                ZoomPresetButton(
                    label: "1x",
                    isSelected: isWideSelected,
                    action: {
                        print("Setting zoom to 1.0x")
                        controller.setZoomPreset(wideZoom)
                    }
                )

                ZoomPresetButton(
                    label: "2x",
                    isSelected: isTeleSelected,
                    action: {
                        print("Setting zoom to 2.0x")
                        controller.setZoomPreset(teleZoom)
                    }
                )

                Slider(
                    value: Binding(
                        get: { controller.zoomSliderValue },
                        set: {
                            print("Slider value: \($0)")
                            controller.updateZoomSlider($0)
                        }
                    ),
                    in: 0...1
                )
                .tint(.white)
            }
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
                .padding(.horizontal, 10) // Slightly wider for better touch target
                .padding(.vertical, 6)   // Slightly taller
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.15))
                )
                .foregroundStyle(isSelected ? .black : .white)
        }
        .buttonStyle(.plain)
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
            // Only show the HUD background for histogram / waveform
            if mode == .histogram || mode == .waveform {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }

            switch mode {
            case .histogram:
                HistogramView(bins: bins)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)

            case .waveform:
                WaveformView(bins: bins)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)

            case .audio, .off:
                // No overlay here – audio meters are handled separately,
                // and "off" means no visual monitoring HUD.
                EmptyView()
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

struct AudioMeterBar: View {
    let level: CGFloat    // 0...1 (RMS-based bar)
    let peakLevel: CGFloat // 0...1 (visual peak position)
    let db: CGFloat       // peak dB, approx -60...0
    let label: String

    private let barHeight: CGFloat = 60

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 8, height: barHeight)

                // Active level bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.yellow, Color.red],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 8, height: max(2, barHeight * level))
                    .animation(.linear(duration: 0.08), value: level)

                // Peak hold line
                RoundedRectangle(cornerRadius: 1)
                    .fill(peakColor)
                    .frame(width: 12, height: 2)
                    .offset(y: -barHeight * peakLevel)
                    .animation(.linear(duration: 0.08), value: peakLevel)
            }

            // Label + dB readout + clip dot
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))

                Text(formattedDB)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))

                if isClipping {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    private var peakColor: Color {
        // Peak line turns red if level is very high
        peakLevel > 0.9 ? .red : .white.opacity(0.9)
    }

    private var isClipping: Bool {
        // Use peak dB for clipping detection
        db >= -1.0
    }

    private var formattedDB: String {
        let value = Int(db.rounded())
        return "\(value) dB"
    }
}
