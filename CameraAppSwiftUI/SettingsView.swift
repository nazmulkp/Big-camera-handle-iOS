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
    private let appStoreID = "6755509693"

    @State private var showMessageComposer = false
    @State private var showMessageErrorAlert = false

    private var emailLabel: String {
        String(
            format: String(localized: "settings.email.label", table: "Settings"),
            email
        )
    }

    private var contactMessageBody: String {
        String(localized: "settings.contact.message.body", table: "Settings")
    }

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "settings.contact.section", table: "Settings")) {
                    Button {
                        openWhatsApp()
                    } label: {
                        Label(
                            String(localized: "settings.whatsapp.button", table: "Settings"),
                            systemImage: "message.circle.fill"
                        )
                    }

                    Button {
                        sendEmail()
                    } label: {
                        Label(emailLabel, systemImage: "envelope.fill")
                    }

                    Button {
                        openIMessageComposer()
                    } label: {
                        Label(
                            String(localized: "settings.sms.button", table: "Settings"),
                            systemImage: "bubble.left.and.bubble.right.fill"
                        )
                    }
                }

                Section(String(localized: "settings.rate.section", table: "Settings")) {
                    Button {
                        openAppStoreReview()
                    } label: {
                        Label(
                            String(localized: "settings.rate.button", table: "Settings"),
                            systemImage: "star.fill"
                        )
                    }
                }

                Section(String(localized: "settings.about.section", table: "Settings")) {
                    HStack {
                        Text("settings.about.app", tableName: "Settings")
                        Spacer()
                        Text("settings.about.app_name", tableName: "Settings")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("settings.about.version", tableName: "Settings")
                        Spacer()
                        Text("settings.version.number", tableName: "Settings")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "settings.navigation.title", table: "Settings"))
            .sheet(isPresented: $showMessageComposer) {
                MessageComposer(
                    recipients: [email],
                    body: contactMessageBody
                )
            }
            .alert(
                String(localized: "settings.message.unavailable.title", table: "Settings"),
                isPresented: $showMessageErrorAlert
            ) {
                Button(String(localized: "settings.common.ok", table: "Settings"), role: .cancel) {}
            } message: {
                Text("settings.message.unavailable.body", tableName: "Settings")
            }
        }
    }

    // MARK: - Helpers

    private func open(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func openWhatsApp() {
        let cleanPhoneNumber = phoneNumber.replacingOccurrences(of: "+", with: "")

        if let url = URL(string: "whatsapp://send?phone=\(cleanPhoneNumber)"),
           UIApplication.shared.canOpenURL(url) {
            open(url: url)
            return
        }

        if let url = URL(string: "https://wa.me/\(cleanPhoneNumber)") {
            open(url: url)
        }
    }

    private func sendEmail() {
        let subject = String(localized: "settings.email.subject", table: "Settings")
        let body = contactMessageBody

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

    private func openAppStoreReview() {
        guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review") else {
            return
        }

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
