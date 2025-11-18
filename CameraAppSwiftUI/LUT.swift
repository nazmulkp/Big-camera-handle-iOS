import SwiftUICore
import SwiftUI
import UIKit

// MARK: - LUT presets

enum LUTPreset: String, CaseIterable, Identifiable {
    case none
    case kodak
    case fujifilm
    case tealOrange
    case imported        // for user .cube

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:       return "None"
        case .kodak:      return "Kodak"
        case .fujifilm:   return "Fujifilm"
        case .tealOrange: return "Teal / Orange"
        case .imported:   return "Imported"
        }
    }

    /// Bundle .cube filename for built-ins (you add these files later).
    var bundleCubeFileName: String? {
        switch self {
        case .none, .imported:
            return nil
        case .kodak:
            return "kodak.cube"
        case .fujifilm:
            return "fujifilm.cube"
        case .tealOrange:
            return "teal_orange.cube"
        }
    }
}



struct CubeImporter: UIViewControllerRepresentable {
    var onImport: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            documentTypes: ["public.item"],
            in: .import
        )
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImport: onImport)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onImport: (URL) -> Void
        init(onImport: @escaping (URL) -> Void) { self.onImport = onImport }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { onImport(url) }
        }
    }
}

//struct LUTSection: View {
//    @ObservedObject var controller: CameraController
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Looks / LUTs")
//                .font(.caption)
//                .foregroundStyle(.white.opacity(0.7))
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 10) {
//                    ForEach(LUTPreset.allCases) { preset in
//                        Button {
//                            controller.setLUTPreset(preset)
//                        } label: {
//                            Text(preset.displayName)
//                                .padding(8)
//                                .background(controller.lutPreset == preset ? Color.blue : Color.gray.opacity(0.3))
//                                .clipShape(RoundedRectangle(cornerRadius: 6))
//                        }
//                    }
//                }
//            }
//
//            Slider(value: $controller.lutIntensity, in: 0...1)
//        }
//    }
//}


extension CameraController {
    // MARK: - LUT management

    func setLUTPreset(_ preset: LUTPreset) {
        lutPreset = preset

        UserDefaults.standard.set(preset.rawValue, forKey: "LUTPreset")

        if preset == .none {
            lutFilter = nil
        } else {
            reloadLUTFilter()
        }
    }

    /// Call this from your importer when user picks a .cube file
    func importLUT(from url: URL) {
        importedLUTURL = url
        lutPreset = .imported
        UserDefaults.standard.set(lutPreset.rawValue, forKey: "LUTPreset")

        reloadLUTFilter()
    }

    func setLUTIntensity(_ value: CGFloat) {
        let clamped = max(0, min(1, value))
        lutIntensity = clamped
        UserDefaults.standard.set(Double(clamped), forKey: "LUTIntensity")
    }

     func reloadLUTFilter() {
        let url: URL?

        switch lutPreset {
        case .none:
            lutFilter = nil
            return

        case .imported:
            url = importedLUTURL

        default:
            if let name = lutPreset.bundleCubeFileName {
                url = Bundle.main.url(forResource: name, withExtension: nil)
            } else {
                url = nil
            }
        }

        guard let cubeURL = url,
              let filter = LUTLoader.colorCubeFilter(fromCubeURL: cubeURL) else {
            print("⚠️ Failed to load LUT filter for \(lutPreset.rawValue)")
            lutFilter = nil
            return
        }

        lutFilter = filter
    }

    /// Apply current LUT + intensity to a CIImage (used for still capture for now)
    func applyCurrentLUT(to image: CIImage) -> CIImage {
        guard let lutFilter,
              lutPreset != .none,
              lutIntensity > 0.001 else {
            return image
        }

        // 1. LUT pass
        lutFilter.setValue(image, forKey: kCIInputImageKey)
        guard let lutOutput = lutFilter.outputImage else {
            return image
        }

        let a = max(0, min(1, lutIntensity))

        if a >= 0.999 {
            return lutOutput
        }

        // 2. Mix original & LUT using a constant grey mask (alpha = intensity)
        let mask = CIImage(
            color: CIColor(red: a, green: a, blue: a, alpha: 1)
        ).cropped(to: image.extent)

        let blended = lutOutput.applyingFilter("CIBlendWithAlphaMask", parameters: [
            kCIInputBackgroundImageKey: image,
            kCIInputMaskImageKey: mask
        ])

        return blended
    }

}

// MARK: - .cube LUT loader

private enum LUTLoader {

    /// Very simple .cube parser → CIColorCubeWithColorSpace filter
    static func colorCubeFilter(fromCubeURL url: URL,
                                colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()) -> CIFilter? {
        guard let text = try? String(contentsOf: url) else {
            print("❌ Failed to read LUT file: \(url.lastPathComponent)")
            return nil
        }

        var lines = text.components(separatedBy: .newlines)
        var size: Int?
        var rgbValues: [Float] = []

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if line.hasPrefix("#") { continue }
            if line.uppercased().hasPrefix("TITLE") { continue }
            if line.uppercased().hasPrefix("DOMAIN_") { continue }

            if line.uppercased().hasPrefix("LUT_3D_SIZE") {
                let comps = line.components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                if let last = comps.last, let n = Int(last) {
                    size = n
                }
                continue
            }

            // data line: "r g b"
            let comps = line.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }

            if comps.count >= 3,
               let r = Float(comps[0]),
               let g = Float(comps[1]),
               let b = Float(comps[2]) {
                rgbValues.append(contentsOf: [r, g, b])
            }
        }

        guard let cubeSize = size else {
            print("❌ .cube file missing LUT_3D_SIZE")
            return nil
        }

        let expectedCount = cubeSize * cubeSize * cubeSize * 3
        guard rgbValues.count >= expectedCount else {
            print("❌ .cube file has insufficient data: \(rgbValues.count) < \(expectedCount)")
            return nil
        }

        // Convert RGB → RGBA with alpha = 1.0
        let cubeDataCount = cubeSize * cubeSize * cubeSize * 4
        var cubeData = [Float](repeating: 0, count: cubeDataCount)

        var srcIndex = 0
        for i in 0..<(cubeSize * cubeSize * cubeSize) {
            cubeData[i * 4 + 0] = rgbValues[srcIndex + 0]
            cubeData[i * 4 + 1] = rgbValues[srcIndex + 1]
            cubeData[i * 4 + 2] = rgbValues[srcIndex + 2]
            cubeData[i * 4 + 3] = 1.0
            srcIndex += 3
        }

        let data = cubeData.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }

        guard let filter = CIFilter(name: "CIColorCubeWithColorSpace") else {
            return nil
        }

        filter.setValue(cubeSize, forKey: "inputCubeDimension")
        filter.setValue(data, forKey: "inputCubeData")
        filter.setValue(colorSpace, forKey: "inputColorSpace")

        return filter
    }
}
