//
//  PermissionGateView.swift
//  CameraAppSwiftUI
//
//  Created by Md Nazmul Hasan on 11/16/25.
//

import SwiftUI
import AVFoundation
import UIKit

@MainActor
final class PermissionViewModel: ObservableObject {
    enum PermissionState {
        case checking
        case needRequest
        case requesting
        case granted
        case denied
    }

    @Published var state: PermissionState = .checking
    @Published var errorMessage: String?

    init() {
        checkCurrentStatus()
    }

    // MARK: - Check existing permissions

    func checkCurrentStatus() {
        let cameraAuth = AVCaptureDevice.authorizationStatus(for: .video)
        let micAuth = AVAudioSession.sharedInstance().recordPermission

        if cameraAuth == .authorized && micAuth == .granted {
            state = .granted
        } else {
            state = .needRequest
        }
    }

    // MARK: - Request permissions (when user taps "Continue")

    func requestPermissions() {
        state = .requesting
        errorMessage = nil

        // Step 1: Camera
        AVCaptureDevice.requestAccess(for: .video) { [weak self] cameraGranted in
            guard let self else { return }

            DispatchQueue.main.async {
                if !cameraGranted {
                    self.state = .denied
                    self.errorMessage = "Camera access is required to capture photos and videos."
                    return
                }

                // Step 2: Microphone
                AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
                    DispatchQueue.main.async {
                        if micGranted {
                            self.state = .granted
                        } else {
                            self.state = .denied
                            self.errorMessage = "Microphone access is required to record audio with your videos."
                        }
                    }
                }
            }
        }
    }

    // MARK: - Open iOS Settings

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

struct PermissionGateView: View {
    @StateObject private var vm = PermissionViewModel()

    var body: some View {
        Group {
            switch vm.state {
            case .granted:
                // ✅ All good → show camera
                CameraRootView()

            case .checking, .requesting, .needRequest, .denied:
                PermissionExplanationScreen(
                    state: vm.state,
                    errorMessage: vm.errorMessage,
                    onContinue: {
                        vm.requestPermissions()
                    },
                    onOpenSettings: {
                        vm.openSettings()
                    }
                )
            }
        }
    }
}

struct PermissionExplanationScreen: View {
    let state: PermissionViewModel.PermissionState
    let errorMessage: String?
    let onContinue: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color.black.opacity(0.95),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Icon / visual
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.pink.opacity(0.8),
                                    Color.orange.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "camera.aperture")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text("Your Camera, Your Looks, Your Way.")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("To start shooting with Moment Pro Camera II, we need access to your camera and microphone.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.pink)
                        Text("Camera access is used to capture photos and videos with full manual controls.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.orange)
                        Text("Microphone access is used to record high-quality audio with your video footage.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, 32)

                if let errorMessage, state == .denied {
                    VStack(spacing: 8) {
                        Text("Permission Needed")
                            .font(.headline)
                            .foregroundStyle(.red.opacity(0.9))

                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Text("You can enable Camera & Microphone access anytime from iOS Settings.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 4)
                }

                Spacer()

                VStack(spacing: 12) {
                    if state == .denied {
                        Button(action: onOpenSettings) {
                            Text("Open Settings")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Button(action: onContinue) {
                            HStack {
                                if state == .requesting {
                                    ProgressView()
                                        .tint(.black)
                                }
                                Text(state == .requesting ? "Requesting Permissions…" : "Continue")
                                    .font(.headline)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 32)
                        .disabled(state == .requesting)
                    }

                    Button {
                        // Optional: later add "Learn more" / privacy link
                    } label: {
                        Text("Why we need these permissions")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                            .underline(false)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

