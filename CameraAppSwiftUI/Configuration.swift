//
//  Configuration.swift
//  CameraAppSwiftUI
//
//  Created by Md Nazmul Hasan on 11/18/25.
//
import Foundation


enum CaptureMode {
    case photo
    case video
}

enum MeterMode: String, CaseIterable, Identifiable {
    case histogram
    case waveform
    case audio        // NEW for audio meters
    case off          // NEW if user wants clean screen

    var id: String { rawValue }

    var label: String {
        switch self {
        case .histogram: return "Histogram"
        case .waveform:  return "Waveform"
        case .audio:     return "Audio"
        case .off:       return "Off"
        }
    }
}
