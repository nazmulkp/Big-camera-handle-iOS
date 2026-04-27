//
//  EnumCase.swift
//  CameraAppSwiftUI
//
//  Created by Md Nazmul Hasan on 11/21/25.
//

import Foundation

// MARK: - Back camera lenses

enum BackCameraLens: String, CaseIterable, Identifiable {
    case ultraWide
    case wide
    case tele

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ultraWide: return "0.5x"
        case .wide:      return "1x"
        case .tele:      return "2x"
        }
    }
}

// MARK: - Video resolution

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

// MARK: - Video frame rate

enum VideoFrameRate: Int, CaseIterable, Identifiable {
    case fps24 = 24
    case fps30 = 30
    case fps60 = 60

    var id: Int { rawValue }

    var label: String {
        "\(rawValue) fps"
    }
}

// MARK: - Video codec

enum VideoCodecPreset: String, CaseIterable, Identifiable {
    case h264
    case hevc

    var id: String { rawValue }

    var label: String {
        switch self {
        case .h264: return "H.264"
        case .hevc: return "HEVC"
        }
    }
}

// MARK: - Video color profile

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

// MARK: - Video bitrate

enum VideoBitratePreset: String, CaseIterable, Identifiable {
    case standard
    case high
    case max

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard:
            return String(localized: "enum.video_bitrate.standard", table: "ProControlsEnums")
        case .high:
            return String(localized: "enum.video_bitrate.high", table: "ProControlsEnums")
        case .max:
            return String(localized: "enum.video_bitrate.max", table: "ProControlsEnums")
        }
    }
}

// MARK: - Flash

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
        case .off:
            return String(localized: "enum.flash.off", table: "ProControlsEnums")
        case .auto:
            return String(localized: "enum.flash.auto", table: "ProControlsEnums")
        case .on:
            return String(localized: "enum.flash.on", table: "ProControlsEnums")
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
        case .auto:
            return String(localized: "enum.exposure.auto", table: "ProControlsEnums")
        case .manual:
            return String(localized: "enum.exposure.manual", table: "ProControlsEnums")
        case .shutterPriority:
            return String(localized: "enum.exposure.shutter_priority", table: "ProControlsEnums")
        case .isoPriority:
            return String(localized: "enum.exposure.iso_priority", table: "ProControlsEnums")
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
        case .auto:
            return String(localized: "enum.white_balance.auto", table: "ProControlsEnums")
        case .manual:
            return String(localized: "enum.white_balance.manual", table: "ProControlsEnums")
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
        case .daylight:
            return String(localized: "enum.white_balance.daylight", table: "ProControlsEnums")
        case .cloudy:
            return String(localized: "enum.white_balance.cloudy", table: "ProControlsEnums")
        case .tungsten:
            return String(localized: "enum.white_balance.tungsten", table: "ProControlsEnums")
        case .fluorescent:
            return String(localized: "enum.white_balance.fluorescent", table: "ProControlsEnums")
        }
    }

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
        case .auto:
            return String(localized: "enum.focus.auto", table: "ProControlsEnums")
        case .manual:
            return String(localized: "enum.focus.manual", table: "ProControlsEnums")
        }
    }
}
