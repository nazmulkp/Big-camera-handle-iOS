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

    // MARK: - Request permissions

    func requestPermissions() {
        state = .requesting
        errorMessage = nil

        AVCaptureDevice.requestAccess(for: .video) { [weak self] cameraGranted in
            guard let self else { return }

            DispatchQueue.main.async {
                if !cameraGranted {
                    self.state = .denied
                    self.errorMessage = String(
                        localized: "permission.error.camera_required",
                        table: "Permission"
                    )
                    return
                }

                AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
                    DispatchQueue.main.async {
                        if micGranted {
                            self.state = .granted
                        } else {
                            self.state = .denied
                            self.errorMessage = String(
                                localized: "permission.error.microphone_required",
                                table: "Permission"
                            )
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

// MARK: - Permission Gate View

struct PermissionGateView: View {
    @StateObject private var vm = PermissionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch vm.state {
            case .granted:
                grantedView

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

    private var grantedView: some View {
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

            VStack(spacing: 18) {
                Text("permission.success.message", tableName: "Permission")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button {
                    dismiss()
                } label: {
                    Text("common.dismiss", tableName: "Permission")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

// MARK: - Permission Explanation Screen

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

                // MARK: - Icon

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
                        .accessibilityHidden(true)
                }

                // MARK: - Title and Subtitle

                VStack(spacing: 8) {
                    Text("permission.title", tableName: "Permission")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("permission.subtitle", tableName: "Permission")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // MARK: - Permission Benefits

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.pink)
                            .accessibilityHidden(true)

                        Text("permission.camera.reason", tableName: "Permission")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.leading)
                    }

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)

                        Text("permission.microphone.reason", tableName: "Permission")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: - Denied Message

                if let errorMessage, state == .denied {
                    VStack(spacing: 8) {
                        Text("permission.needed.title", tableName: "Permission")
                            .font(.headline)
                            .foregroundStyle(.red.opacity(0.9))

                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Text("permission.settings.helper", tableName: "Permission")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 4)
                }

                Spacer()

                // MARK: - Action Button

                VStack(spacing: 12) {
                    if state == .denied {
                        Button(action: onOpenSettings) {
                            Text("permission.open_settings", tableName: "Permission")
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

                                Text(
                                    state == .requesting
                                    ? String(localized: "permission.requesting", table: "Permission")
                                    : String(localized: "common.continue", table: "Permission")
                                )
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

                    Text("permission.privacy.message", tableName: "Permission")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
        }
    }
}
