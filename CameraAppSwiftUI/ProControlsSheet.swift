// MARK: - Pro Controls Sheet (all "deep" controls live here)

import SwiftUI
import AVFoundation

struct ProControlsSheet: View {
    
    @ObservedObject var controller: CameraController
    @Binding var mode: CaptureMode
    @Binding var meterMode: MeterMode
    @Binding var isLeftHandedLayout: Bool
    @Binding var isZenMode: Bool
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WhiteBalanceSection(controller: controller)
                    ExposureSection(controller: controller)
                    FocusSection(controller: controller)
                    FormatSection(controller: controller)
                    VideoSection(controller: controller)
                    MonitoringSection(controller: controller, meterMode: $meterMode)
                    
                    Section {
                        Toggle(isOn: $isLeftHandedLayout) {
                            Text("Left-handed layout")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                    } header: {
                        Text("Layout")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Section {
                        Toggle(isOn: $isZenMode) {
                            Text("Zen Mode (Clean HUD)")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        Text("Hide all controls except shutter, readout, and zoom. Tap the screen to temporarily show the full HUD.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    } header: {
                        Text("HUD")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
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

// MARK: - White balance section with Custom Segmented Control

struct WhiteBalanceSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "White Balance")

            // Custom segmented control
            HStack(spacing: 0) {
                ForEach(WhiteBalanceMode.allCases) { mode in
                    Button(action: {
                        // Immediate update
                        controller.whiteBalanceMode = mode
                        controller.setWhiteBalanceMode(mode)
                    }) {
                        Text(mode.label)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                controller.whiteBalanceMode == mode ?
                                Color.blue : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(
                                controller.whiteBalanceMode == mode ?
                                .white : .white.opacity(0.8)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

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

// MARK: - Exposure section with Custom Segmented Control

struct ExposureSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Exposure")

            // Custom segmented control for Exposure Mode
            HStack(spacing: 0) {
                ForEach(ExposureControlMode.allCases) { mode in
                    Button(action: {
                        // Immediate update
                        controller.exposureMode = mode
                        controller.setExposureMode(mode)
                    }) {
                        Text(mode.shortLabel)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                controller.exposureMode == mode ?
                                Color.blue : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(
                                controller.exposureMode == mode ?
                                .white : .white.opacity(0.8)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

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

// MARK: - Focus section with Custom Segmented Control

struct FocusSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Focus")

            // Custom segmented control for Focus Mode
            HStack(spacing: 0) {
                ForEach(FocusControlMode.allCases) { mode in
                    Button(action: {
                        // Immediate update
                        controller.focusMode = mode
                        controller.setFocusMode(mode)
                    }) {
                        Text(mode.label)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                controller.focusMode == mode ?
                                Color.blue : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(
                                controller.focusMode == mode ?
                                .white : .white.opacity(0.8)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

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

// MARK: - Format section with Custom Segmented Control

struct FormatSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Format")

            // Custom segmented control for Photo Format
            HStack(spacing: 0) {
                ForEach(PhotoFormat.allCases) { format in
                    let supported: Bool = {
                        switch format {
                        case .jpeg:   return true
                        case .heif:   return controller.supportsHEIF
                        case .raw:    return controller.supportsRAW
                        case .proRAW: return controller.supportsProRAW
                        }
                    }()

                    Button(action: {
                        // Check if format is supported before updating
                        guard supported else { return }
                        controller.photoFormat = format
                    }) {
                        HStack {
                            Text(format.shortLabel)
                            if !supported {
                                Text("∙ N/A")
                                    .font(.caption2)
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            controller.photoFormat == format && supported ?
                            Color.blue : (supported ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                        )
                        .foregroundColor(
                            controller.photoFormat == format && supported ?
                            .white : (supported ? .white.opacity(0.8) : .white.opacity(0.3))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!supported)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

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

// MARK: - Monitoring section with Custom Segmented Control

struct MonitoringSection: View {
    @ObservedObject var controller: CameraController
    @Binding var meterMode: MeterMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Monitoring")

            // Custom segmented control for Meter Mode
            HStack(spacing: 0) {
                ForEach(MeterMode.allCases) { mode in
                    Button(action: {
                        // Immediate update
                        meterMode = mode
                    }) {
                        Text(mode.label)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                meterMode == mode ?
                                Color.blue : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(
                                meterMode == mode ?
                                .white : .white.opacity(0.8)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            // Audio Gain + Mute
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Audio Gain")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text("\(Int(controller.audioGainDB.rounded())) dB")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.7))
                }

                Slider(
                    value: Binding(
                        get: { Double(controller.audioGainDB) },
                        set: { controller.audioGainDB = CGFloat($0) }
                    ),
                    in: -24...24,
                    step: 1
                )

                Toggle(isOn: Binding(
                    get: { controller.isAudioMuted },
                    set: { controller.setAudioMuted($0) }
                )) {
                    Text("Mute")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .toggleStyle(.switch)
            }
        }
    }
}

// MARK: - Video section with Custom Segmented Controls

struct VideoSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Video")

            // Resolution - Custom segmented control
            VStack(alignment: .leading, spacing: 4) {
                Text("Resolution")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                
                HStack(spacing: 0) {
                    ForEach(VideoResolution.allCases) { resolution in
                        Button(action: {
                            controller.videoResolution = resolution
                            controller.setVideoResolution(resolution)
                        }) {
                            Text(resolution.label)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(
                                    controller.videoResolution == resolution ?
                                    Color.blue : Color.gray.opacity(0.3)
                                )
                                .foregroundColor(
                                    controller.videoResolution == resolution ?
                                    .white : .white.opacity(0.8)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }

            // FPS + Stabilization
            VStack(alignment: .leading, spacing: 8) {
                Text("Frame Rate")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                
                HStack(spacing: 12) {
                    // FPS - Custom segmented control
                    HStack(spacing: 0) {
                        ForEach(VideoFrameRate.allCases) { fps in
                            Button(action: {
                                controller.videoFrameRate = fps
                                controller.setVideoFrameRate(fps)
                            }) {
                                Text(fps.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        controller.videoFrameRate == fps ?
                                        Color.blue : Color.gray.opacity(0.3)
                                    )
                                    .foregroundColor(
                                        controller.videoFrameRate == fps ?
                                        .white : .white.opacity(0.8)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                    // Stabilization Toggle
                    VStack {
                        Toggle(isOn: Binding(
                            get: { controller.videoStabilizationEnabled },
                            set: { controller.setVideoStabilizationEnabled($0) }
                        )) {
                            Text("Stab")
                                .font(.caption2)
                        }
                        .toggleStyle(.switch)
                        .labelsHidden()
                        
                        Text("Stab")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            // Codec - Custom segmented control
            VStack(alignment: .leading, spacing: 4) {
                Text("Codec")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                
                HStack(spacing: 0) {
                    ForEach(VideoCodecPreset.allCases) { codec in
                        Button(action: {
                            controller.videoCodec = codec
                            controller.setVideoCodec(codec)
                        }) {
                            Text(codec.label)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(
                                    controller.videoCodec == codec ?
                                    Color.blue : Color.gray.opacity(0.3)
                                )
                                .foregroundColor(
                                    controller.videoCodec == codec ?
                                    .white : .white.opacity(0.8)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }

            // Color profile - Custom segmented control
            VStack(alignment: .leading, spacing: 4) {
                Text("Color Profile")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                
                HStack(spacing: 0) {
                    ForEach(VideoColorProfile.allCases) { profile in
                        Button(action: {
                            controller.videoColorProfile = profile
                            controller.setVideoColorProfile(profile)
                        }) {
                            Text(profile.label)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(
                                    controller.videoColorProfile == profile ?
                                    Color.blue : Color.gray.opacity(0.3)
                                )
                                .foregroundColor(
                                    controller.videoColorProfile == profile ?
                                    .white : .white.opacity(0.8)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }

            // Bitrate - Custom segmented control
            VStack(alignment: .leading, spacing: 4) {
                Text("Bitrate")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                
                HStack(spacing: 0) {
                    ForEach(VideoBitratePreset.allCases) { preset in
                        Button(action: {
                            controller.videoBitratePreset = preset
                            controller.setVideoBitratePreset(preset)
                        }) {
                            Text(preset.label)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(
                                    controller.videoBitratePreset == preset ?
                                    Color.blue : Color.gray.opacity(0.3)
                                )
                                .foregroundColor(
                                    controller.videoBitratePreset == preset ?
                                    .white : .white.opacity(0.8)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }

            Text(videoSummary)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
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
