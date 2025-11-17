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

// UIView whose *layer* is an AVCaptureVideoPreviewLayer
final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black

        let previewLayer = view.videoPreviewLayer
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait

        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Make sure layer always matches view bounds
        uiView.videoPreviewLayer.frame = uiView.bounds
    }
}
