//
//  SettingsView.swift
//  CameraAppSwiftUI
//
//  Created by MacBook Air M1 on 26/11/25.
//

import SwiftUI
import MessageUI
import AVFoundation

struct SettingsView: View {
    private let phoneNumber = "+8801904993197"
    private let email = "sohagswift@gmail.com"
    private let appStoreID = "6755509693" // TODO: replace with your real App Store ID

    @State private var showMessageComposer = false
    @State private var showMessageErrorAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("Contact the Developer") {
                    Button {
                        openWhatsApp()
                    } label: {
                        Label("Chat on WhatsApp", systemImage: "message.circle.fill")
                    }

                    Button {
                        sendEmail()
                    } label: {
                        Label("Email: \(email)", systemImage: "envelope.fill")
                    }

                    Button {
                        openIMessageComposer()
                    } label: {
                        Label("iMessage / SMS", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                }

                // 🔥 New Rate & Review section
                Section("Rate & Review") {
                    Button {
                        openAppStoreReview()
                    } label: {
                        Label("Rate Air Camera on the App Store", systemImage: "star.fill")
                    }
                }

                Section("About") {
                    HStack {
                        Text("App")
                        Spacer()
                        Text("Air Camera")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.2")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showMessageComposer) {
                MessageComposer(
                    recipients: [email],
                    body: "Hi Sohag,\n\nI am using Air Camera and…"
                )
            }
            .alert("Messages not available", isPresented: $showMessageErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device cannot send messages.")
            }
        }
    }

    // MARK: - Helpers

    private func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func openWhatsApp() {
        if let url = URL(string: "whatsapp://send?phone=\(phoneNumber.replacingOccurrences(of: "+", with: ""))"),
           UIApplication.shared.canOpenURL(url) {
            open(url: url)
            return
        }

        if let url = URL(string: "https://wa.me/\(phoneNumber.replacingOccurrences(of: "+", with: ""))") {
            open(url: url)
        }
    }

    private func sendEmail() {
        let subject = "Air Camera feedback"
        let body = "Hi Sohag,\n\nI am using Air Camera and…"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            open(url: url)
        }
    }

    private func openIMessageComposer() {
        if MFMessageComposeViewController.canSendText() {
            showMessageComposer = true
        } else {
            showMessageErrorAlert = true
        }
    }

    // 👇 New: open App Store review page
    private func openAppStoreReview() {
        // Replace appStoreID with your real one from App Store Connect
        guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review") else { return }
        open(url: url)
    }
}



struct MessageComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.recipients = recipients
        vc.body = body
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
}
