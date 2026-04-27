// MARK: - Pro Controls Sheet (all "deep" controls live here)

import SwiftUI
import AVFoundation

struct ProControlsSheet: View {

    @ObservedObject var controller: CameraController
    @Binding var meterMode: MeterMode
    @Binding var isLeftHandedLayout: Bool
    @Binding var isZenMode: Bool

    @Environment(\.dismiss) private var dismiss

    var batterySymbolName: String {
        let percent = controller.batteryStatusSummaryInt()

        let bucket: Int
        switch percent {
        case ..<15:
            bucket = 0
        case ..<40:
            bucket = 25
        case ..<65:
            bucket = 50
        case ..<90:
            bucket = 75
        default:
            bucket = 100
        }

        return "battery.\(bucket)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Label {
                            Text(controller.batteryStatusSummary())
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: batterySymbolName)
                        }

                        Divider()
                            .frame(height: 12)

                        Label {
                            Text(controller.storageStatusSummary())
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "externaldrive")
                        }
                    }
                    .font(.caption2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.4))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)

                    WhiteBalanceSection(controller: controller)
                    ExposureSection(controller: controller)
                    FocusSection(controller: controller)
                    LensSection(controller: controller)
                    FormatSection(controller: controller)
                    VideoSection(controller: controller)
                    LUTSection(controller: controller)
                    MonitoringSection(controller: controller, meterMode: $meterMode)

                    Section {
                        Toggle(isOn: $isLeftHandedLayout) {
                            Text("pro.layout.left_handed", tableName: "ProControls")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                    } header: {
                        Text("pro.layout.section", tableName: "ProControls")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Section {
                        Toggle(isOn: $isZenMode) {
                            Text("pro.hud.zen_mode", tableName: "ProControls")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }

                        Text("pro.hud.zen_description", tableName: "ProControls")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    } header: {
                        Text("pro.hud.section", tableName: "ProControls")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "pro.navigation.title", table: "ProControls"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        resetToDefaults()
                    } label: {
                        Text("pro.toolbar.reset", tableName: "ProControls")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "pro.toolbar.done", table: "ProControls")) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Reset all pro controls to defaults & close sheet

    private func resetToDefaults() {
        controller.whiteBalanceMode = .auto
        controller.tempSliderValue = 0.5
        controller.tintSliderValue = 0.5
        controller.setWhiteBalanceMode(.auto)

        controller.exposureMode = .auto
        controller.shutterSliderValue = 0.5
        controller.isoSliderValue = 0.5
        controller.evSliderValue = 0.5
        controller.autoISOMinSliderValue = 0.0
        controller.autoISOMaxSliderValue = 1.0
        controller.setExposureMode(.auto)

        controller.focusMode = .auto
        controller.focusSliderValue = 0.5
        controller.setFocusMode(.auto)

        controller.photoFormat = .heif

        controller.videoResolution = .res1080p
        controller.videoFrameRate = .fps30
        controller.videoCodec = .hevc
        controller.videoColorProfile = .sdr
        controller.videoStabilizationEnabled = true
        controller.videoBitratePreset = .standard

        meterMode = .histogram
        controller.audioGainDB = 0
        controller.setAudioMuted(false)

        isLeftHandedLayout = false
        isZenMode = false

        controller.zoomSliderValue = 0.0
        controller.applyZoomSettings()

        controller.applyExposureSettings()
        controller.applyEVSettings()
        controller.applyWhiteBalanceSettings()
        controller.applyFocusSettings()
        controller.applyVideoConfiguration()

        dismiss()
    }
}

// MARK: - White Balance Section

struct WhiteBalanceSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: String(localized: "pro.white_balance.section", table: "ProControls"))

            HStack(spacing: 0) {
                ForEach(WhiteBalanceMode.allCases) { mode in
                    Button(action: {
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
                    title: String(localized: "pro.white_balance.temp", table: "ProControls"),
                    value: Binding(
                        get: { controller.tempSliderValue },
                        set: { controller.updateTemperatureSlider($0) }
                    ),
                    enabled: controller.whiteBalanceMode == .manual
                )

                SettingSliderRow(
                    title: String(localized: "pro.white_balance.tint", table: "ProControls"),
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

// MARK: - Exposure Section

struct ExposureSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: String(localized: "pro.exposure.section", table: "ProControls"))

            HStack(spacing: 0) {
                ForEach(ExposureControlMode.allCases) { mode in
                    Button(action: {
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

            HStack(spacing: 12) {
                SettingSliderRow(
                    title: String(localized: "pro.exposure.shutter", table: "ProControls"),
                    value: Binding(
                        get: { controller.shutterSliderValue },
                        set: { controller.updateShutterSlider($0) }
                    ),
                    enabled: !(controller.exposureMode == .auto ||
                               controller.exposureMode == .isoPriority)
                )

                SettingSliderRow(
                    title: String(localized: "pro.exposure.iso", table: "ProControls"),
                    value: Binding(
                        get: { controller.isoSliderValue },
                        set: { controller.updateISOSlider($0) }
                    ),
                    enabled: !(controller.exposureMode == .auto ||
                               controller.exposureMode == .shutterPriority)
                )
            }

            SettingSliderRow(
                title: String(localized: "pro.exposure.ev_compensation", table: "ProControls"),
                value: Binding(
                    get: { controller.evSliderValue },
                    set: { controller.updateEVSlider($0) }
                ),
                enabled: true
            )

            Text(controller.evDisplayString())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 12) {
                SettingSliderRow(
                    title: String(localized: "pro.exposure.auto_iso_min", table: "ProControls"),
                    value: Binding(
                        get: { controller.autoISOMinSliderValue },
                        set: { controller.updateAutoISOMinSlider($0) }
                    ),
                    enabled: true
                )

                SettingSliderRow(
                    title: String(localized: "pro.exposure.auto_iso_max", table: "ProControls"),
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

// MARK: - Focus Section

struct FocusSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: String(localized: "pro.focus.section", table: "ProControls"))

            HStack(spacing: 0) {
                ForEach(FocusControlMode.allCases) { mode in
                    Button(action: {
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
                title: String(localized: "pro.focus.manual", table: "ProControls"),
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

// MARK: - Format Section

struct FormatSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: String(localized: "pro.format.section", table: "ProControls"))

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
                        guard supported else { return }
                        controller.photoFormat = format
                    }) {
                        HStack {
                            Text(format.shortLabel)
                            if !supported {
                                Text("pro.format.not_available", tableName: "ProControls")
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
            return String(localized: "pro.format.jpeg.description", table: "ProControls")
        case .heif:
            return String(localized: "pro.format.heif.description", table: "ProControls")
        case .raw:
            return String(localized: "pro.format.raw.description", table: "ProControls")
        case .proRAW:
            return String(localized: "pro.format.proraw.description", table: "ProControls")
        }
    }
}

// MARK: - Monitoring Section

struct MonitoringSection: View {
    @ObservedObject var controller: CameraController
    @Binding var meterMode: MeterMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: String(localized: "pro.monitoring.section", table: "ProControls"))

            HStack(spacing: 0) {
                ForEach(MeterMode.allCases) { mode in
                    Button(action: {
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

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("pro.monitoring.audio_gain", tableName: "ProControls")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    Text(
                        String(
                            format: String(localized: "pro.monitoring.audio_gain_value", table: "ProControls"),
                            Int(controller.audioGainDB.rounded())
                        )
                    )
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
                    Text("pro.monitoring.mute", tableName: "ProControls")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .toggleStyle(.switch)
            }
        }
    }
}

// MARK: - Video Section

struct VideoSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: String(localized: "pro.video.section", table: "ProControls"))

            VStack(alignment: .leading, spacing: 4) {
                Text("pro.video.resolution", tableName: "ProControls")
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

            VStack(alignment: .leading, spacing: 8) {
                Text("pro.video.frame_rate", tableName: "ProControls")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 12) {
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

                    VStack {
                        Toggle(isOn: Binding(
                            get: { controller.videoStabilizationEnabled },
                            set: { controller.setVideoStabilizationEnabled($0) }
                        )) {
                            Text("pro.video.stab", tableName: "ProControls")
                                .font(.caption2)
                        }
                        .toggleStyle(.switch)
                        .labelsHidden()

                        Text("pro.video.stab", tableName: "ProControls")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("pro.video.codec", tableName: "ProControls")
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

            VStack(alignment: .leading, spacing: 4) {
                Text("pro.video.color_profile", tableName: "ProControls")
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

            VStack(alignment: .leading, spacing: 4) {
                Text("pro.video.bitrate", tableName: "ProControls")
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
        let stab = controller.videoStabilizationEnabled
            ? String(localized: "pro.video.stab_on", table: "ProControls")
            : String(localized: "pro.video.stab_off", table: "ProControls")
        let codec = controller.videoCodec.label
        let color = controller.videoColorProfile.label
        let bitrate = controller.videoBitratePreset.label

        return "\(res) • \(fps) • \(stab) • \(codec) • \(color) • \(bitrate)"
    }
}

// MARK: - LUT Section

struct LUTSection: View {
    @ObservedObject var controller: CameraController
    @State private var showImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: String(localized: "pro.lut.section", table: "ProControls"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LUTPreset.allCases) { preset in
                        Button {
                            if preset == .imported {
                                if controller.lutPreset == .imported && controller.previewImage != nil {
                                    controller.setLUTPreset(.imported)
                                } else {
                                    showImporter = true
                                }
                            } else {
                                controller.setLUTPreset(preset)
                            }
                        } label: {
                            Text(preset.displayName)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(controller.lutPreset == preset
                                              ? Color.blue
                                              : Color.gray.opacity(0.3))
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("pro.lut.strength", tableName: "ProControls")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text(String(format: "%.0f%%", controller.lutIntensity * 100))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.7))
                }

                Slider(
                    value: Binding(
                        get: { Double(controller.lutIntensity) },
                        set: { controller.setLUTIntensity(CGFloat($0)) }
                    ),
                    in: 0...1
                )
            }

            Toggle(isOn: Binding(
                get: { controller.applyLUTToCaptures },
                set: { controller.applyLUTToCaptures = $0 }
            )) {
                Text("pro.lut.apply_to_captures", tableName: "ProControls")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    controller.importLUT(from: url)
                }
            case .failure(let error):
                print("❌ LUT import failed: \(error)")
            }
        }
    }
}

// MARK: - Lens Section

struct LensSection: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: String(localized: "pro.lens.section", table: "ProControls"))

            HStack(spacing: 0) {
                ForEach(controller.availableBackCameras) { lens in
                    Button(action: {
                        controller.setBackCamera(lens)
                    }) {
                        Text(lens.label)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                controller.activeBackCamera == lens
                                ? Color.blue
                                : Color.gray.opacity(0.3)
                            )
                            .foregroundColor(
                                controller.activeBackCamera == lens
                                ? .white
                                : .white.opacity(0.8)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(controller.isRecording)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            if controller.isRecording {
                Text("pro.lens.stop_recording", tableName: "ProControls")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}
