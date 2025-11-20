//
//  EnumCase.swift
//  CameraAppSwiftUI
//
//  Created by Md Nazmul Hasan on 11/21/25.
//

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
