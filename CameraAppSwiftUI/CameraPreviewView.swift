//
//  CameraPreviewView.swift
//  CameraAppSwiftUI
//
//  Created by Md Nazmul Hasan on 11/16/25.
//

import SwiftUI
import AVFoundation

import SwiftUI
import AVFoundation

//// UIView whose *layer* is an AVCaptureVideoPreviewLayer
//final class PreviewView: UIView {
//    override class var layerClass: AnyClass {
//        AVCaptureVideoPreviewLayer.self
//    }
//
//    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
//        return layer as! AVCaptureVideoPreviewLayer
//    }
//}
//
//struct CameraPreviewView: UIViewRepresentable {
//    let session: AVCaptureSession
//
//    func makeUIView(context: Context) -> PreviewView {
//        let view = PreviewView()
//        view.backgroundColor = .black
//
//        let previewLayer = view.videoPreviewLayer
//        previewLayer.session = session
//        previewLayer.videoGravity = .resizeAspectFill
//        previewLayer.connection?.videoOrientation = .portrait
//
//        return view
//    }
//
//    func updateUIView(_ uiView: PreviewView, context: Context) {
//        // Make sure layer always matches view bounds
//        uiView.videoPreviewLayer.frame = uiView.bounds
//    }
//}


//
//  CameraPreviewView.swift
//  CameraAppSwiftUI
//
//  Created by Md Nazmul Hasan on 11/16/25.
//

import SwiftUI
import AVFoundation

/// CI-backed live preview that shows the controller's latest LUT-applied frame.
struct CameraPreviewView: View {
    @ObservedObject var controller: CameraController

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let cgImage = controller.previewImage {
                    Image(decorative: cgImage, scale: 1.0, orientation: .right)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    // Fallback while first frame arrives
                    Color.black
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
    }
}
