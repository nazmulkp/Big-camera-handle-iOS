import Foundation
import AVFoundation
import UIKit
import Photos
import UniformTypeIdentifiers
import CoreImage

// Shared CI context for histogram rendering
fileprivate let histogramCIContext = CIContext()

enum VideoResolution: String, CaseIterable, Identifiable {
    case res720p
    case res1080p
    case res4k

    var id: String { rawValue }

    var label: String {
        switch self {
        case .res720p:   return "720p"
        case .res1080p:  return "1080p"
        case .res4k:     return "4K"
        }
    }
}

enum VideoFrameRate: Int, CaseIterable, Identifiable {
    case fps24 = 24
    case fps30 = 30
    case fps60 = 60

    var id: Int { rawValue }

    var label: String {
        "\(rawValue) fps"
    }
}

enum VideoCodecPreset: String, CaseIterable, Identifiable {
    case h264
    case hevc

    var id: String { rawValue }

    var label: String {
        switch self {
        case .h264:       return "H.264"
        case .hevc:       return "HEVC"
        }
    }
}

enum VideoColorProfile: String, CaseIterable, Identifiable {
    case sdr
    case hdr
    case appleLogLike

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sdr:          return "SDR"
        case .hdr:          return "HDR"
        case .appleLogLike: return "Log"
        }
    }
}

enum VideoBitratePreset: String, CaseIterable, Identifiable {
    case standard
    case high
    case max

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Std"
        case .high:     return "High"
        case .max:      return "Max"
        }
    }
}


enum FlashState: String, CaseIterable, Identifiable {
    case off
    case auto
    case on

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .off:  return "bolt.slash"
        case .auto: return "bolt.badge.a"
        case .on:   return "bolt.fill"
        }
    }

    var label: String {
        switch self {
        case .off:  return "Off"
        case .auto: return "Auto"
        case .on:   return "On"
        }
    }
}


// MARK: - Exposure control modes

enum ExposureControlMode: String, CaseIterable, Identifiable {
    case auto
    case manual
    case shutterPriority
    case isoPriority

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .auto:            return "Auto"
        case .manual:          return "M"
        case .shutterPriority: return "S"
        case .isoPriority:     return "ISO"
        }
    }
}

// MARK: - Photo formats

enum PhotoFormat: String, CaseIterable, Identifiable {
    case jpeg
    case heif
    case raw
    case proRAW

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .jpeg:   return "JPEG"
        case .heif:   return "HEIF"
        case .raw:    return "RAW"
        case .proRAW: return "ProRAW"
        }
    }
}

// MARK: - White balance

enum WhiteBalanceMode: String, CaseIterable, Identifiable {
    case auto
    case manual

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto:   return "Auto"
        case .manual: return "Manual"
        }
    }
}

enum WhiteBalancePreset: String, CaseIterable, Identifiable {
    case daylight
    case cloudy
    case tungsten
    case fluorescent

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daylight:    return "Day"
        case .cloudy:      return "Cloudy"
        case .tungsten:    return "Tungsten"
        case .fluorescent: return "Fluoro"
        }
    }

    /// Approximate temperature (K) & tint values.
    var temperatureAndTint: (temperature: Float, tint: Float) {
        switch self {
        case .daylight:    return (5500, 0)
        case .cloudy:      return (6500, 0)
        case .tungsten:    return (3200, 0)
        case .fluorescent: return (4000, 10)
        }
    }
}

// MARK: - Focus control

enum FocusControlMode: String, CaseIterable, Identifiable {
    case auto
    case manual

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto:   return "AF"
        case .manual: return "MF"
        }
    }
}




@MainActor
final class CameraController: NSObject, ObservableObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    // MARK: - Audio monitoring

    private let audioDataOutput = AVCaptureAudioDataOutput()
    private let audioDataQueue  = DispatchQueue(label: "AudioDataQueue")

    @Published var audioLevelLeft: CGFloat  = 0.0   // 0...1
    @Published var audioLevelRight: CGFloat = 0.0   // 0...1

    
    // Video HUD
    @Published var recordingDuration: TimeInterval = 0

    // private
    private var recordingStartDate: Date?
    private var recordingTimer: Timer?

    
    // Video configuration
    @Published var videoResolution: VideoResolution = .res1080p
    @Published var videoFrameRate: VideoFrameRate = .fps30
    @Published var videoCodec: VideoCodecPreset = .hevc
    @Published var videoColorProfile: VideoColorProfile = .sdr
    @Published var videoStabilizationEnabled: Bool = true
    @Published var videoBitratePreset: VideoBitratePreset = .standard
    @Published var supportsProRes: Bool = false


    // MARK: - Published properties (UI state)

    @Published var isSessionRunning = false
    @Published var lastCapturedImage: UIImage?

    // Exposure
    @Published var exposureMode: ExposureControlMode = .auto
    @Published var shutterSliderValue: Double = 0.5   // 0...1
    @Published var isoSliderValue: Double = 0.5       // 0...1

    // EV compensation (-2...+2 mapped from slider 0...1)
    @Published var evSliderValue: Double = 0.5

    // Auto ISO min/max range (sliders 0...1 mapped onto [minISO, maxISO])
    @Published var autoISOMinSliderValue: Double = 0.0
    @Published var autoISOMaxSliderValue: Double = 1.0

    // Format selection
    @Published var photoFormat: PhotoFormat = .heif
    @Published var supportsHEIF: Bool = true
    @Published var supportsRAW: Bool = false
    @Published var supportsProRAW: Bool = false

    // White balance
    @Published var whiteBalanceMode: WhiteBalanceMode = .auto
    @Published var tempSliderValue: Double = 0.5      // 0...1
    @Published var tintSliderValue: Double = 0.5      // 0...1

    // Focus
    @Published var focusMode: FocusControlMode = .auto
    @Published var focusSliderValue: Double = 0.5     // 0...1

    // Histogram (for HUD)
    @Published var histogramBins: [CGFloat] = Array(repeating: 0, count: 64)

    // Zoom
    @Published var zoomSliderValue: Double = 0.0      // 0...1
    @Published var zoomFactor: CGFloat = 1.0          // actual device zoom

    // Video recording
    @Published var isRecording = false

    // MARK: - AVFoundation internals
    
    private var countdownTimer: Timer?
    private var videoConfigUpdateScheduled = false

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    private let photoOutput = AVCapturePhotoOutput()

    // Histogram video output
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataQueue  = DispatchQueue(label: "camera.video.queue")

    // Movie output for recording
    private let movieOutput = AVCaptureMovieFileOutput()

    fileprivate var videoDeviceInput: AVCaptureDeviceInput?

    // Exposure ranges
    private var minISO: Float = 50
    private var maxISO: Float = 1600
    private var minExposureDuration: Double = 1.0 / 10000.0 // seconds
    private var maxExposureDuration: Double = 1.0 / 2.0     // seconds

    // White balance ranges
    private let minTemperature: Float = 2500   // K
    private let maxTemperature: Float = 7500   // K
    private let minTint: Float = -150
    private let maxTint: Float = 150

    // Zoom ranges
    private var minZoomFactor: CGFloat = 1.0
    private var maxZoomFactor: CGFloat = 6.0
    private let baseFocalLengthMM: Double = 24.0   // approx wide angle base

    // Track current capture format for saving
    private var currentCaptureFormat: PhotoFormat = .heif
    
    // Quick actions
    @Published var flashModeState: FlashState = .off
    @Published var isGridEnabled: Bool = false

    @Published var captureTimerSeconds: Int = 0    // 0, 3, 10
    @Published var countdownRemaining: Int = 0     // active countdown while timer runs

    @Published var isAEAFLocked: Bool = false


    // MARK: - Init

    override init() {
        super.init()
        configureSession()
    }

    // MARK: - Session configuration

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high   // good default for photo + 1080p video

            // Remove existing inputs
            self.session.inputs.forEach { self.session.removeInput($0) }

            // Video input – back wide camera
            guard
                let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .back
                )
            else {
                print("❌ No back camera found")
                self.session.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.videoDeviceInput = input
                } else {
                    print("❌ Cannot add camera input")
                }
            } catch {
                print("❌ Error creating camera input: \(error)")
            }

            // Audio input for video recording
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                do {
                    let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                    if self.session.canAddInput(audioInput) {
                        self.session.addInput(audioInput)
                    } else {
                        print("❌ Cannot add audio input")
                    }
                } catch {
                    print("❌ Error creating audio input: \(error)")
                }
            }

            // Photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.session.addOutput(self.photoOutput)
            } else {
                print("❌ Cannot add photo output")
            }

            // Video output for histogram / waveform
            if self.session.canAddOutput(self.videoDataOutput) {
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                self.videoDataOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoDataQueue)
                self.session.addOutput(self.videoDataOutput)
            } else {
                print("❌ Cannot add video data output")
            }

            // Movie output for video recording
            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            } else {
                print("❌ Cannot add movie output")
            }

            // Exposure & zoom ranges from active format
            if let dev = self.videoDeviceInput?.device {
                let format = dev.activeFormat
                self.minISO = format.minISO
                self.maxISO = format.maxISO

                let minDur = CMTimeGetSeconds(format.minExposureDuration)
                let maxDur = CMTimeGetSeconds(format.maxExposureDuration)

                self.minExposureDuration = max(minDur, 1.0 / 100000.0)
                self.maxExposureDuration = max(maxDur, self.minExposureDuration * 10)

                // Zoom range
                self.minZoomFactor = dev.minAvailableVideoZoomFactor
                self.maxZoomFactor = min(dev.maxAvailableVideoZoomFactor, 6.0)

                print("📷 ISO range: \(self.minISO) – \(self.maxISO)")
                print("📷 Shutter range: \(self.minExposureDuration)s – \(self.maxExposureDuration)s")
                print("📷 Zoom range: \(self.minZoomFactor)x – \(self.maxZoomFactor)x")

                let initialZoom = self.minZoomFactor

                Task { @MainActor in
                    self.zoomFactor = initialZoom
                    self.zoomSliderValue = self.sliderValue(forZoom: initialZoom)
                }
            }

            // Capabilities: HEIF / RAW / ProRAW-ish
            let heifSupported = self.photoOutput.availablePhotoCodecTypes.contains(.hevc)
            let hasRaw = !self.photoOutput.availableRawPhotoPixelFormatTypes.isEmpty

            var proRawSupported = false
            if #available(iOS 14.3, *) {
                if self.photoOutput.isAppleProRAWSupported {
                    let types = self.photoOutput.availableRawPhotoPixelFormatTypes
                    proRawSupported = types.contains {
                        AVCapturePhotoOutput.isAppleProRAWPixelFormat($0)
                    }
                }
            }

            Task { @MainActor in
                self.supportsHEIF = heifSupported
                self.supportsRAW = hasRaw
                self.supportsProRAW = proRawSupported

                if !heifSupported && self.photoFormat == .heif {
                    self.photoFormat = .jpeg
                }
                if !hasRaw && (self.photoFormat == .raw || self.photoFormat == .proRAW) {
                    self.photoFormat = heifSupported ? .heif : .jpeg
                }
            }
            
            // Audio data output for level meters
            if self.session.canAddOutput(self.audioDataOutput) {
                self.audioDataOutput.setSampleBufferDelegate(self, queue: self.audioDataQueue)
                self.session.addOutput(self.audioDataOutput)
            } else {
                print("❌ Cannot add audio data output")
            }


            self.session.commitConfiguration()
        }
    }
   // MARK: - Session control

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            Task { @MainActor in
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            Task { @MainActor in
                self.isSessionRunning = false
            }
        }
    }
    
    // MARK: - Audio level analysis

    nonisolated private func processAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var length = 0
        var totalLength = 0
        var dataPointer: UnsafeMutablePointer<Int8>?

        let status = CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: &length,
            totalLengthOut: &totalLength,
            dataPointerOut: &dataPointer
        )

        guard status == kCMBlockBufferNoErr,
              let dataPointer = dataPointer,
              length > 0 else { return }

        let sampleCount = length / MemoryLayout<Int16>.size
        if sampleCount == 0 { return }

        let maxSamples = min(sampleCount, 2048)

        var sum: Float = 0
        var peak: Float = 0

        dataPointer.withMemoryRebound(to: Int16.self, capacity: sampleCount) { ptr in
            for i in 0..<maxSamples {
                let s = Float(ptr[i]) / Float(Int16.max)
                let a = abs(s)
                sum += a * a
                if a > peak { peak = a }
            }
        }

        let rms = sqrt(sum / Float(maxSamples))
        guard rms > 0 else { return }

        let db = 20 * log10(rms)
        let normalized = max(0, min(1, (db + 60) / 60))

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.audioLevelLeft  = CGFloat(normalized)
            self.audioLevelRight = CGFloat(normalized)
        }
    }



    // MARK: - Flash / Torch

    func cycleFlashMode(isVideo: Bool) {
        let next: FlashState
        switch flashModeState {
        case .off:  next = .auto
        case .auto: next = .on
        case .on:   next = .off
        }
        flashModeState = next

        if isVideo {
            let shouldTorch = (next == .on)
            setTorchEnabled(shouldTorch)
        }
    }

    private func setTorchEnabled(_ enabled: Bool) {
        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDeviceInput?.device,
                  device.hasTorch else { return }

            do {
                try device.lockForConfiguration()
                if enabled {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print("❌ Failed to set torch: \(error)")
            }
        }
    }

    // MARK: - Photo capture (with formats)
    

    func capturePhoto() {
        let selectedFormat = photoFormat
        currentCaptureFormat = selectedFormat

        sessionQueue.async { [weak self] in
            guard let self else { return }

            let settings: AVCapturePhotoSettings

            switch selectedFormat {
            case .jpeg:
                if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                } else {
                    settings = AVCapturePhotoSettings()
                }

            case .heif:
                if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else {
                    settings = AVCapturePhotoSettings()
                }

            case .raw:
                if !self.photoOutput.availableRawPhotoPixelFormatTypes.isEmpty {
                    let rawType = self.photoOutput.availableRawPhotoPixelFormatTypes.first!
                    settings = AVCapturePhotoSettings(
                        rawPixelFormatType: rawType,
                        processedFormat: [AVVideoCodecKey: AVVideoCodecType.hevc]
                    )
                } else {
                    print("⚠️ RAW not supported, falling back to JPEG")
                    settings = AVCapturePhotoSettings()
                }

            case .proRAW:
                if #available(iOS 14.3, *),
                   self.supportsProRAW,
                   let rawType = self.photoOutput.availableRawPhotoPixelFormatTypes.first(
                        where: { AVCapturePhotoOutput.isAppleProRAWPixelFormat($0) }
                   ) {
                    settings = AVCapturePhotoSettings(
                        rawPixelFormatType: rawType,
                        processedFormat: [AVVideoCodecKey: AVVideoCodecType.hevc]
                    )
                } else {
                    print("⚠️ ProRAW not supported/enabled, falling back to RAW/JPEG")
                    if !self.photoOutput.availableRawPhotoPixelFormatTypes.isEmpty {
                        let rawType = self.photoOutput.availableRawPhotoPixelFormatTypes.first!
                        settings = AVCapturePhotoSettings(
                            rawPixelFormatType: rawType,
                            processedFormat: [AVVideoCodecKey: AVVideoCodecType.hevc]
                        )
                    } else {
                        settings = AVCapturePhotoSettings()
                    }
                }
            }

            settings.isHighResolutionPhotoEnabled = true
            
            // Apply flash mode for stills (if supported)
            switch flashModeState {
            case .off:
                if self.photoOutput.supportedFlashModes.contains(.off) {
                    settings.flashMode = .off
                }
            case .auto:
                if self.photoOutput.supportedFlashModes.contains(.auto) {
                    settings.flashMode = .auto
                }
            case .on:
                if self.photoOutput.supportedFlashModes.contains(.on) {
                    settings.flashMode = .on
                }
            }


            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    // MARK: - Grid

    func toggleGrid() {
        isGridEnabled.toggle()
    }

    // MARK: - Timer

    func cycleTimerMode() {
        switch captureTimerSeconds {
        case 0:
            captureTimerSeconds = 3
        case 3:
            captureTimerSeconds = 10
        default:
            captureTimerSeconds = 0
        }
    }

    func triggerPhotoCapture() {
        // No timer → capture immediately
        guard captureTimerSeconds > 0 else {
            capturePhoto()
            return
        }

        // Start countdown
        countdownTimer?.invalidate()
        countdownRemaining = captureTimerSeconds

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            if self.countdownRemaining > 1 {
                self.countdownRemaining -= 1
            } else {
                timer.invalidate()
                self.countdownRemaining = 0
                self.capturePhoto()
            }
        }
    }

    // MARK: - AE/AF Lock

    func toggleAEAFLock() {
        isAEAFLocked.toggle()

        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDeviceInput?.device else { return }

            do {
                try device.lockForConfiguration()

                if self.isAEAFLocked {
                    if device.isFocusModeSupported(.locked) {
                        device.focusMode = .locked
                    }
                    if device.isExposureModeSupported(.locked) {
                        device.exposureMode = .locked
                    }
                } else {
                    device.unlockForConfiguration()
                    // Re-apply our current exposure/focus modes
                    self.applyFocusSettings()
                    self.applyExposureSettings()
                    return
                }

                device.unlockForConfiguration()
            } catch {
                print("❌ Failed to toggle AE/AF lock: \(error)")
            }
        }
    }


    // MARK: - Video Recording

    func startRecording() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.movieOutput.isRecording else { return }

            let tempURL = FileManager.default
                .temporaryDirectory
                .appendingPathComponent("clip-\(UUID().uuidString).mov")

            self.movieOutput.startRecording(to: tempURL, recordingDelegate: self)
            
            // After starting movie output
            startRecordingTimer()
        }
    }

    func stopRecording() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.movieOutput.isRecording else { return }
            self.movieOutput.stopRecording()
            // 👇 add this
            self.stopRecordingTimer()
        }
    }

    // MARK: - Tap-to-focus & expose

    func focusAndExpose(at point: CGPoint, viewSize: CGSize) {
        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDeviceInput?.device else { return }

            let devicePoint = CGPoint(
                x: point.x / viewSize.width,
                y: point.y / viewSize.height
            )

            do {
                try device.lockForConfiguration()

                // Exposure point always follows tap
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = devicePoint
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                }

                // Focus tap only when in AF mode
                if self.focusMode == .auto,
                   device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                }

                device.unlockForConfiguration()
            } catch {
                print("❌ Failed to lock device for focus/exposure tap: \(error)")
            }
        }
    }

    // MARK: - Exposure controls with throttling

    private func scheduleExposureUpdate() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(applyExposureSettingsObjC),
            object: nil
        )
        perform(#selector(applyExposureSettingsObjC), with: nil, afterDelay: 0.03)
    }

    @objc private func applyExposureSettingsObjC() {
        applyExposureSettings()
    }

    func setExposureMode(_ mode: ExposureControlMode) {
        exposureMode = mode
        scheduleExposureUpdate()
        scheduleEVUpdate()
    }

    func updateShutterSlider(_ value: Double) {
        shutterSliderValue = value
        scheduleExposureUpdate()
    }

    func updateISOSlider(_ value: Double) {
        isoSliderValue = value
        scheduleExposureUpdate()
    }

    func applyExposureSettings() {
        let mode = exposureMode
        let shutterNorm = shutterSliderValue.clamped(to: 0...1)
        let isoNorm = isoSliderValue.clamped(to: 0...1)

        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDeviceInput?.device else { return }

            do {
                try device.lockForConfiguration()

                switch mode {
                case .auto:
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }

                case .manual, .shutterPriority, .isoPriority:
                    let iso = self.isoFromNormalized(isoNorm)
                    let duration = self.durationFromNormalized(shutterNorm)

                    let currentISO = device.iso
                    let currentDuration = device.exposureDuration

                    let finalISO: Float
                    let finalDuration: CMTime

                    switch mode {
                    case .manual:
                        finalISO = iso
                        finalDuration = duration
                    case .shutterPriority:
                        finalISO = currentISO
                        finalDuration = duration
                    case .isoPriority:
                        finalISO = iso
                        finalDuration = currentDuration
                    default:
                        finalISO = iso
                        finalDuration = duration
                    }

                    if device.isExposureModeSupported(.custom) {
                        device.setExposureModeCustom(
                            duration: finalDuration,
                            iso: finalISO,
                            completionHandler: nil
                        )
                    } else {
                        print("⚠️ Custom exposure not supported on this device")
                    }
                }

                device.unlockForConfiguration()
            } catch {
                print("❌ Failed to lock device for exposure: \(error)")
            }
        }
    }
    
    // MARK: - Video HUD helpers

    func videoStatusSummary() -> String {
        let res  = videoResolution.label       // 720p / 1080p / 4K
        let fps  = videoFrameRate.label        // 24 fps / 30 fps / 60 fps
        let codec = videoCodec.label           // H.264 / HEVC
        return "\(res) • \(fps) • \(codec)"
    }

    func recordingDurationString() -> String {
        let total = Int(recordingDuration)
        let hours = total / 3600
        let mins  = (total % 3600) / 60
        let secs  = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }

    private func startRecordingTimer() {
        recordingStartDate = Date()
        recordingTimer?.invalidate()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.recordingDuration = 0

            self.recordingTimer = Timer.scheduledTimer(
                withTimeInterval: 0.5,
                repeats: true
            ) { [weak self] _ in
                guard let self,
                      let start = self.recordingStartDate else { return }
                self.recordingDuration = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopRecordingTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.recordingTimer?.invalidate()
            self.recordingTimer = nil
            self.recordingStartDate = nil
            self.recordingDuration = 0
        }
    }


    // MARK: - EV controls with throttling

    private func scheduleEVUpdate() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(applyEVSettingsObjC),
            object: nil
        )
        perform(#selector(applyEVSettingsObjC), with: nil, afterDelay: 0.03)
    }

    @objc private func applyEVSettingsObjC() {
        applyEVSettings()
    }

    func updateEVSlider(_ value: Double) {
        evSliderValue = value
        scheduleEVUpdate()
    }

    private func evValue() -> Double {
        let t = evSliderValue.clamped(to: 0...1)
        return -2.0 + 4.0 * t   // -2 → +2
    }

    func evReadoutShort() -> String {
        let ev = evValue()
        return String(format: "%+.1f", ev)  // "+0.3", "-1.0", "0.0"
    }

    func evDisplayString() -> String {
        "EV \(evReadoutShort())"
    }

    func applyEVSettings() {
        let bias = Float(evValue())

        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDeviceInput?.device else { return }

            do {
                try device.lockForConfiguration()
                device.setExposureTargetBias(bias, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {
                print("❌ Failed to set exposure target bias: \(error)")
            }
        }
    }

    // MARK: - Auto ISO range

    func updateAutoISOMinSlider(_ value: Double) {
        let clamped = value.clamped(to: 0...autoISOMaxSliderValue)
        autoISOMinSliderValue = clamped
        scheduleExposureUpdate()
    }

    func updateAutoISOMaxSlider(_ value: Double) {
        let clamped = value.clamped(to: autoISOMinSliderValue...1.0)
        autoISOMaxSliderValue = clamped
        scheduleExposureUpdate()
    }

    func autoISORangeDisplayString() -> String {
        let (lo, hi) = effectiveISORange()
        return "Auto ISO \(Int(lo.rounded()))–\(Int(hi.rounded()))"
    }

    // MARK: - White balance controls with throttling

    private func scheduleWhiteBalanceUpdate() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(applyWhiteBalanceSettingsObjC),
            object: nil
        )
        perform(#selector(applyWhiteBalanceSettingsObjC), with: nil, afterDelay: 0.03)
    }

    @objc private func applyWhiteBalanceSettingsObjC() {
        applyWhiteBalanceSettings()
    }

    func setWhiteBalanceMode(_ mode: WhiteBalanceMode) {
        whiteBalanceMode = mode
        scheduleWhiteBalanceUpdate()
    }

    func updateTemperatureSlider(_ value: Double) {
        tempSliderValue = value
        scheduleWhiteBalanceUpdate()
    }

    func updateTintSlider(_ value: Double) {
        tintSliderValue = value
        scheduleWhiteBalanceUpdate()
    }

    func applyWhiteBalancePreset(_ preset: WhiteBalancePreset) {
        let (temp, tint) = preset.temperatureAndTint
        let tNorm = (temp - minTemperature) / (maxTemperature - minTemperature)
        let tintNorm = (tint - minTint) / (maxTint - minTint)

        tempSliderValue = Double(tNorm.clamped(to: 0...1))
        tintSliderValue = Double(tintNorm.clamped(to: 0...1))

        whiteBalanceMode = .manual
        scheduleWhiteBalanceUpdate()
    }

    func applyWhiteBalanceSettings() {
        let mode = whiteBalanceMode
        let tempNorm = tempSliderValue.clamped(to: 0...1)
        let tintNorm = tintSliderValue.clamped(to: 0...1)

        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDeviceInput?.device else { return }

            do {
                try device.lockForConfiguration()

                switch mode {
                case .auto:
                    if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                        device.whiteBalanceMode = .continuousAutoWhiteBalance
                    } else if device.isWhiteBalanceModeSupported(.autoWhiteBalance) {
                        device.whiteBalanceMode = .autoWhiteBalance
                    }

                case .manual:
                    guard device.isWhiteBalanceModeSupported(.locked) else {
                        print("⚠️ Manual white balance not supported")
                        break
                    }

                    let temp = self.temperatureFromNormalized(tempNorm)
                    let tint = self.tintFromNormalized(tintNorm)

                    let t = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                        temperature: temp,
                        tint: tint
                    )

                    var gains = device.deviceWhiteBalanceGains(for: t)

                    let maxGain = device.maxWhiteBalanceGain
                    gains.redGain   = max(1.0, min(gains.redGain,   maxGain))
                    gains.greenGain = max(1.0, min(gains.greenGain, maxGain))
                    gains.blueGain  = max(1.0, min(gains.blueGain,  maxGain))

                    device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
                }

                device.unlockForConfiguration()
            } catch {
                print("❌ Failed to lock device for white balance: \(error)")
            }
        }
    }

    // MARK: - Focus controls with throttling

    private func scheduleFocusUpdate() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(applyFocusSettingsObjC),
            object: nil
        )
        perform(#selector(applyFocusSettingsObjC), with: nil, afterDelay: 0.03)
    }

    @objc private func applyFocusSettingsObjC() {
        applyFocusSettings()
    }

    func setFocusMode(_ mode: FocusControlMode) {
        focusMode = mode
        scheduleFocusUpdate()
    }

    func updateFocusSlider(_ value: Double) {
        focusSliderValue = value
        scheduleFocusUpdate()
    }

    func applyFocusSettings() {
        let mode = focusMode
        let norm = focusSliderValue.clamped(to: 0...1)

        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDeviceInput?.device else { return }

            do {
                try device.lockForConfiguration()

                switch mode {
                case .auto:
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    } else if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                    }

                case .manual:
                    guard device.isLockingFocusWithCustomLensPositionSupported else {
                        print("⚠️ Manual lens position not supported on this device")
                        if device.isFocusModeSupported(.continuousAutoFocus) {
                            device.focusMode = .continuousAutoFocus
                        }
                        break
                    }

                    let lensPosition = Float(norm)  // 0.0 (far) → 1.0 (near)
                    device.setFocusModeLocked(
                        lensPosition: lensPosition,
                        completionHandler: nil
                    )
                }

                device.unlockForConfiguration()
            } catch {
                print("❌ Failed to lock device for focus: \(error)")
            }
        }
    }

    // MARK: - Zoom controls with throttling

    private func scheduleZoomUpdate() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(applyZoomSettingsObjC),
            object: nil
        )
        perform(#selector(applyZoomSettingsObjC), with: nil, afterDelay: 0.02)
    }

    @objc private func applyZoomSettingsObjC() {
        applyZoomSettings()
    }

    func updateZoomSlider(_ value: Double) {
        zoomSliderValue = value
        scheduleZoomUpdate()
    }

    func setZoomPreset(_ factor: CGFloat) {
        let clamped = max(minZoomFactor, min(factor, maxZoomFactor))
        let sliderVal = sliderValue(forZoom: clamped)
        zoomSliderValue = sliderVal
        scheduleZoomUpdate()
    }

    func applyZoomSettings() {
        let factor = zoomFactor(fromSlider: zoomSliderValue)

        sessionQueue.async { [weak self] in
            guard let self,
                  let device = self.videoDeviceInput?.device else { return }

            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = factor
                device.unlockForConfiguration()

                Task { @MainActor in
                    self.zoomFactor = factor
                }
            } catch {
                print("❌ Failed to lock device for zoom: \(error)")
            }
        }
    }

    // MARK: - Readouts for UI

    func shutterDisplayString() -> String {
        if exposureMode == .auto {
            return "Shutter Auto"
        }

        let seconds = shutterSecondsFromSlider()

        if seconds >= 1.0 {
            return String(format: "%.1fs", seconds)
        } else {
            let denom = Int((1.0 / seconds).rounded())
            return "1/\(denom)s"
        }
    }

    func isoDisplayString() -> String {
        if exposureMode == .auto {
            return "ISO Auto"
        }

        let (_, _) = effectiveISORange()
        let iso = isoFromNormalized(isoSliderValue.clamped(to: 0...1))
        return "ISO \(Int(iso.rounded()))"
    }

    func whiteBalanceDisplayString() -> String {
        switch whiteBalanceMode {
        case .auto:
            return "WB Auto"
        case .manual:
            let temp = Int(temperatureFromNormalized(tempSliderValue.clamped(to: 0...1)))
            let tint = Int(tintFromNormalized(tintSliderValue.clamped(to: 0...1)))
            let tintString = tint == 0 ? "0" : (tint > 0 ? "+\(tint)" : "\(tint)")
            return "WB \(temp)K • Tint \(tintString)"
        }
    }

    func focusDisplayString() -> String {
        switch focusMode {
        case .auto:
            return "Focus Auto"
        case .manual:
            let pos = focusSliderValue.clamped(to: 0...1)
            return String(format: "Focus %.2f", pos)
        }
    }

    func shutterReadoutShort() -> String {
        if exposureMode == .auto {
            return "Auto"
        }

        let seconds = shutterSecondsFromSlider()

        if seconds >= 1.0 {
            return String(format: "%.1f", seconds)  // "0.5"
        } else {
            let denom = Int((1.0 / seconds).rounded())
            return "1/\(denom)"                    // "1/250"
        }
    }

    func isoReadoutShort() -> String {
        if exposureMode == .auto {
            return "Auto"
        }

        let iso = isoFromNormalized(isoSliderValue.clamped(to: 0...1))
        return "\(Int(iso.rounded()))"
    }

    func focalLengthReadout() -> String {
        let approx = baseFocalLengthMM * Double(zoomFactor)
        return "\(Int(approx.rounded()))mm"
    }

    private func shutterSecondsFromSlider() -> Double {
        let t = shutterSliderValue.clamped(to: 0...1)
        let minLog = log10(minExposureDuration)
        let maxLog = log10(maxExposureDuration)
        let logDur = minLog + t * (maxLog - minLog)
        return pow(10.0, logDur)
    }

    // MARK: - Mapping helpers

    private func isoFromNormalized(_ t: Double) -> Float {
        let tClamped = t.clamped(to: 0...1)
        let (minEff, maxEff) = effectiveISORange()
        return minEff + Float(tClamped) * (maxEff - minEff)
    }

    private func effectiveISORange() -> (Float, Float) {
        let minUser = minISO + Float(autoISOMinSliderValue.clamped(to: 0...1)) * (maxISO - minISO)
        let maxUser = minISO + Float(autoISOMaxSliderValue.clamped(to: 0...1)) * (maxISO - minISO)

        let lo = min(minUser, maxUser)
        let hi = max(minUser, maxUser)
        return (lo, hi)
    }

    private func durationFromNormalized(_ t: Double) -> CMTime {
        let seconds = shutterSecondsFromSlider()
        return CMTimeMakeWithSeconds(seconds, preferredTimescale: 1_000_000_000)
    }

    private func temperatureFromNormalized(_ t: Double) -> Float {
        let tClamped = t.clamped(to: 0...1)
        return minTemperature + Float(tClamped) * (maxTemperature - minTemperature)
    }

    private func tintFromNormalized(_ t: Double) -> Float {
        let tClamped = t.clamped(to: 0...1)
        return minTint + Float(tClamped) * (maxTint - minTint)
    }

    private func zoomFactor(fromSlider tIn: Double) -> CGFloat {
        let t = tIn.clamped(to: 0...1)
        let minZ = max(minZoomFactor, 0.1)
        let maxZ = max(maxZoomFactor, minZ + 0.01)

        let ratio = maxZ / minZ
        let factor = minZ * pow(ratio, CGFloat(t))
        return max(minZ, min(factor, maxZ))
    }

    private func sliderValue(forZoom zIn: CGFloat) -> Double {
        let minZ = max(minZoomFactor, 0.1)
        let maxZ = max(maxZoomFactor, minZ + 0.01)
        let z = max(minZ, min(zIn, maxZ))
        let ratio = maxZ / minZ
        guard ratio > 1 else { return 0 }
        let t = log(z / minZ) / log(ratio)
        return Double(t.clamped(to: 0...1))
    }

    // MARK: - Save to Photos (processed data only)

    @MainActor
    private func handleCaptureResult(processedData: Data?) {
        if let processedData,
           let image = UIImage(data: processedData) {
            self.lastCapturedImage = image
        }

        saveToPhotoLibrary(processedData: processedData)
    }

    @MainActor
    private func saveToPhotoLibrary(processedData: Data?) {
        let format = currentCaptureFormat

        guard let data = processedData else {
            print("⚠️ No image data to save.")
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                print("⚠️ Photos permission not granted: \(status.rawValue)")
                return
            }

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                let opts = PHAssetResourceCreationOptions()

                if #available(iOS 14.0, *) {
                    switch format {
                    case .jpeg:
                        opts.uniformTypeIdentifier = UTType.jpeg.identifier
                    case .heif:
                        opts.uniformTypeIdentifier = UTType.heic.identifier
                    case .raw,
                         .proRAW:
                        opts.uniformTypeIdentifier = UTType.rawImage.identifier
                    }
                }

                request.addResource(with: .photo, data: data, options: opts)
            } completionHandler: { success, error in
                if !success {
                    print("❌ Failed to save to Photos: \(String(describing: error))")
                } else {
                    print("✅ Saved photo to Photos as \(format.rawValue)")
                }
            }
        }
    }
}



// MARK: - Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Photo delegate

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        if let error {
            print("❌ Error processing photo: \(error)")
            return
        }

        let processedData = photo.fileDataRepresentation()

        Task { @MainActor [weak self] in
            self?.handleCaptureResult(processedData: processedData)
        }
    }
}

// MARK: - Movie recording delegate

extension CameraController: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput,
                                didStartRecordingTo fileURL: URL,
                                from connections: [AVCaptureConnection]) {
        Task { @MainActor [weak self] in
            self?.isRecording = true
            print("🎥 Started recording to: \(fileURL.lastPathComponent)")
        }
    }

    nonisolated func fileOutput(_ output: AVCaptureFileOutput,
                                didFinishRecordingTo outputFileURL: URL,
                                from connections: [AVCaptureConnection],
                                error: Error?) {
        Task { @MainActor [weak self] in
            self?.isRecording = false
        }

        if let error {
            print("❌ Video recording error: \(error)")
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                print("⚠️ Photos permission not granted for video.")
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            } completionHandler: { success, saveError in
                if !success {
                    print("❌ Failed to save video: \(String(describing: saveError))")
                } else {
                    print("✅ Saved video to Photos")
                }

                try? FileManager.default.removeItem(at: outputFileURL)
            }
        }
    }
}

// MARK: - Video data output (Histogram) + Audio data output (Meters)

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate{
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        // 🔊 Audio: level meters
        if output === audioDataOutput {
            processAudioSampleBuffer(sampleBuffer)
            return
        }

        // 🎥 Video: histogram
        guard output === videoDataOutput,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let ciImage  = CIImage(cvPixelBuffer: pixelBuffer)
        let extent   = ciImage.extent
        let binCount = 64

        guard let filter = CIFilter(name: "CIAreaHistogram") else { return }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: "inputExtent")
        filter.setValue(binCount, forKey: "inputCount")
        filter.setValue(1.0, forKey: "inputScale")

        guard let outputImage = filter.outputImage else { return }

        var bitmap = [Float](repeating: 0, count: binCount * 4)

        histogramCIContext.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: binCount * MemoryLayout<Float>.size * 4,
            bounds: CGRect(x: 0, y: 0, width: binCount, height: 1),
            format: .RGBAf,
            colorSpace: nil
        )

        var bins = [CGFloat](repeating: 0, count: binCount)
        for i in 0..<binCount {
            let r = bitmap[i * 4]
            bins[i] = CGFloat(max(r, 0))
        }

        if let maxVal = bins.max(), maxVal > 0 {
            for i in 0..<binCount {
                bins[i] /= maxVal
            }
        }

        Task { @MainActor [weak self] in
            self?.histogramBins = bins
        }
    }
}

extension CameraController {
    // MARK: - Video configuration

    private func scheduleVideoConfigUpdate() {
        // Keep it simple: debounce a bit
        guard !videoConfigUpdateScheduled else { return }
        videoConfigUpdateScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            self.videoConfigUpdateScheduled = false
            self.applyVideoConfiguration()
        }
    }

    func setVideoResolution(_ res: VideoResolution) {
        videoResolution = res
        scheduleVideoConfigUpdate()
    }

    func setVideoFrameRate(_ fps: VideoFrameRate) {
        videoFrameRate = fps
        scheduleVideoConfigUpdate()
    }

    func setVideoCodec(_ codec: VideoCodecPreset) {
        videoCodec = codec
        scheduleVideoConfigUpdate()
    }

    func setVideoColorProfile(_ profile: VideoColorProfile) {
        videoColorProfile = profile
        scheduleVideoConfigUpdate()
    }

    func setVideoStabilizationEnabled(_ enabled: Bool) {
        videoStabilizationEnabled = enabled
        scheduleVideoConfigUpdate()
    }

    func setVideoBitratePreset(_ preset: VideoBitratePreset) {
        videoBitratePreset = preset
        scheduleVideoConfigUpdate()
        // Note: AVCaptureMovieFileOutput doesn't expose direct bitrate controls.
        // This is a UI hint for a future AVAssetWriter pipeline.
    }

    func applyVideoConfiguration() {
        sessionQueue.async(execute: { [weak self] in
            guard let strongSelf = self,
                  let device = strongSelf.videoDeviceInput?.device else { return }
            
            strongSelf.session.beginConfiguration()
            
            // 1) Resolution via sessionPreset
            let targetPreset: AVCaptureSession.Preset
            switch strongSelf.videoResolution {
            case .res720p:
                targetPreset = .hd1280x720
            case .res1080p:
                targetPreset = .hd1920x1080
            case .res4k:
                if strongSelf.session.canSetSessionPreset(.hd4K3840x2160) {
                    targetPreset = .hd4K3840x2160
                } else {
                    targetPreset = .hd1920x1080
                }
            }
            
            if strongSelf.session.canSetSessionPreset(targetPreset) {
                strongSelf.session.sessionPreset = targetPreset
            }
            
            // 2) Frame rate (fps) – best effort on activeFormat
            let desiredFPS = strongSelf.videoFrameRate.rawValue
            let ranges = device.activeFormat.videoSupportedFrameRateRanges
            if let range = ranges.first(where: {
                Double(desiredFPS) >= $0.minFrameRate && Double(desiredFPS) <= $0.maxFrameRate
            }) {
                do {
                    try device.lockForConfiguration()
                    device.activeVideoMinFrameDuration = CMTime(
                        value: 1,
                        timescale: CMTimeScale(desiredFPS)
                    )
                    device.activeVideoMaxFrameDuration = CMTime(
                        value: 1,
                        timescale: CMTimeScale(desiredFPS)
                    )
                    device.unlockForConfiguration()
                } catch {
                    print("❌ Failed to set frame rate: \(error)")
                }
            } else {
                print("⚠️ Desired FPS \(desiredFPS) not supported on this format")
            }
            
            // 3) Stabilization, codec, color space on movieOutput connection
            if let connection = strongSelf.movieOutput.connection(with: .video) {
                // Stabilization
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode =
                    strongSelf.videoStabilizationEnabled ? .cinematic : .off
                }
                
                // Codec (H.264 / HEVC) – best effort
                if #available(iOS 11.0, *) {
                    let available = strongSelf.movieOutput.availableVideoCodecTypes
                    
                    let desiredCodec: AVVideoCodecType = {
                        switch strongSelf.videoCodec {
                        case .h264: return .h264
                        case .hevc: return .hevc
                        }
                    }()
                    
                    let codecToUse: AVVideoCodecType
                    if available.contains(desiredCodec) {
                        codecToUse = desiredCodec
                    } else if available.contains(.hevc) {
                        codecToUse = .hevc
                    } else if available.contains(.h264) {
                        codecToUse = .h264
                    } else if let first = available.first {
                        codecToUse = first
                    } else {
                        codecToUse = .h264
                    }
                    
                    strongSelf.movieOutput.setOutputSettings(
                        [AVVideoCodecKey: codecToUse],
                        for: connection
                    )
                }
                
                if let connection = strongSelf.movieOutput.connection(with: .video) {
                    // Stabilization
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode =
                        strongSelf.videoStabilizationEnabled ? .cinematic : .off
                    }
                    
                    // Codec (H.264 / HEVC) – best effort
                    if #available(iOS 11.0, *) {
                        let available = strongSelf.movieOutput.availableVideoCodecTypes
                        
                        let desiredCodec: AVVideoCodecType = {
                            switch strongSelf.videoCodec {
                            case .h264: return .h264
                            case .hevc: return .hevc
                            }
                        }()
                        
                        let codecToUse: AVVideoCodecType
                        if available.contains(desiredCodec) {
                            codecToUse = desiredCodec
                        } else if available.contains(.hevc) {
                            codecToUse = .hevc
                        } else if available.contains(.h264) {
                            codecToUse = .h264
                        } else if let first = available.first {
                            codecToUse = first
                        } else {
                            codecToUse = .h264
                        }
                        
                        strongSelf.movieOutput.setOutputSettings(
                            [AVVideoCodecKey: codecToUse],
                            for: connection
                        )
                    }
                }
                
                strongSelf.session.commitConfiguration()
              }
            })
        }

   }
