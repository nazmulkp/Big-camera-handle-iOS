//
//  EasyCameraHomeView.swift
//  CameraAppSwiftUI
//
//  Created by MacBook Air M1 on 21/11/25.
//

import SwiftUI
import StoreKit
import AVFAudio
import AVFoundation

// MARK: - Model

struct BlogPost: Identifiable, Codable {
    let id: Int
    let title: String
    let subtitle: String
    let readTime: Int
    let body: String
}

// MARK: - Store

// MARK: - Store

// MARK: - Store

final class BlogStore: ObservableObject {
    @Published var posts: [BlogPost] = []

    init() {
        load()
    }

    func load() {
        let languageCode = currentBlogLanguageCode()

        let possibleFileNames = [
            "blogs_\(languageCode)",
            "blogs_en",
            "blogs"
        ]

        guard let selectedFileName = possibleFileNames.first(where: {
            Bundle.main.url(forResource: $0, withExtension: "json") != nil
        }),
        let url = Bundle.main.url(forResource: selectedFileName, withExtension: "json") else {
            print("⚠️ No blog JSON file found")
            return
        }

        print("✅ Loading blog file:", selectedFileName)

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([BlogPost].self, from: data)

            DispatchQueue.main.async {
                self.posts = decoded
            }
        } catch {
            print("⚠️ Failed to decode \(selectedFileName).json:", error)
        }
    }

    private func currentBlogLanguageCode() -> String {
        for preferred in Locale.preferredLanguages {
            let identifier = preferred.replacingOccurrences(of: "_", with: "-")
            let locale = Locale(identifier: identifier)
            let languageCode = locale.languageCode ?? "en"
            let regionCode = locale.regionCode ?? ""

            // Chinese
            if identifier.hasPrefix("zh-Hans") {
                return "zh-Hans"
            }

            if identifier.hasPrefix("zh-Hant") {
                return "zh-Hant"
            }

            if languageCode == "zh" {
                switch regionCode {
                case "TW", "HK", "MO":
                    return "zh-Hant"
                default:
                    return "zh-Hans"
                }
            }

            // Portuguese
            if languageCode == "pt" {
                return "pt-BR"
            }

            // Other supported languages
            switch languageCode {
            case "en":
                return "en"
            case "ar":
                return "ar"
            case "fr":
                return "fr"
            case "de":
                return "de"
            case "it":
                return "it"
            case "ja":
                return "ja"
            case "ko":
                return "ko"
            case "ru":
                return "ru"
            case "es":
                return "es"
            case "tr":
                return "tr"
            case "hi":
                return "hi"
            default:
                continue
            }
        }

        return "en"
    }
}

// MARK: - Home View

struct EasyCameraHomeView: View {
    @StateObject private var blogStore = BlogStore()

    @State private var showCamera = false
    @State private var showPermission = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack {
                    // MARK: - Blog List

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(blogStore.posts) { post in
                                NavigationLink {
                                    BlogDetailView(post: post)
                                } label: {
                                    BlogRow(post: post)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }

                    // MARK: - Bottom Camera Button

                    VStack(spacing: 8) {
                        Divider()

                        Button {
                            let cameraAuth = AVCaptureDevice.authorizationStatus(for: .video)
                            let micAuth = AVAudioSession.sharedInstance().recordPermission

                            if cameraAuth == .authorized && micAuth == .granted {
                                showCamera = true
                            } else {
                                showPermission = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("home.open_camera.title", tableName: "Home")
                                        .font(.headline)
                                        .multilineTextAlignment(.leading)

                                    Text("home.open_camera.subtitle", tableName: "Home")
                                        .font(.caption)
                                        .opacity(0.8)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.subheadline)
                                    .accessibilityHidden(true)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    .background(.ultraThinMaterial)
                }
                .listStyle(.plain)
                .navigationTitle(String(localized: "home.navigation.title", table: "Home"))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .accessibilityLabel(
                                    Text("home.settings.button.accessibility_label", tableName: "Home")
                                )
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraRootView()
        }
        .sheet(isPresented: $showPermission) {
            PermissionGateView()
        }
        .onAppear {
            handleRating()
        }
    }

    private func handleRating() {
        if TStorage.shouldRated == 4 {
            rateApp()
            TStorage.shouldRated += 1
        } else if TStorage.shouldRated < 10 {
            TStorage.shouldRated += 1
        }
    }

    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Blog Row

struct BlogRow: View {
    let post: BlogPost

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Text(post.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

// MARK: - Blog Detail View

struct BlogDetailView: View {
    let post: BlogPost

    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0

    private var navigationBarOpacity: Double {
        let progress = max(0, min(1, scrollOffset / 100))
        return Double(progress)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(post.title)
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)

                                Text(post.subtitle)
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.top, 24)

                        Divider()
                            .padding(.vertical, 8)

                        EnhancedMarkdownText(text: post.body)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear
                                .onAppear {
                                    updateScrollOffset(
                                        contentGeometry: contentGeometry,
                                        geometry: geometry
                                    )
                                }
                                .onChange(of: contentGeometry.frame(in: .global).minY) { _ in
                                    updateScrollOffset(
                                        contentGeometry: contentGeometry,
                                        geometry: geometry
                                    )
                                }
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func updateScrollOffset(contentGeometry: GeometryProxy, geometry: GeometryProxy) {
        let yPosition = contentGeometry.frame(in: .global).minY
        let offset = max(0, -yPosition - geometry.safeAreaInsets.top)
        scrollOffset = offset
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Markdown Text

struct EnhancedMarkdownText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let attributed = try? AttributedString(
                markdown: text,
                options: .init(interpretedSyntax: .full)
            ) {
                Text(attributed)
                    .font(.system(.body, design: .serif))
                    .lineSpacing(8)
                    .tracking(0.3)
                    .foregroundColor(.primary.opacity(0.9))
                    .multilineTextAlignment(.leading)
            } else {
                Text(text)
                    .font(.system(.body, design: .serif))
                    .lineSpacing(8)
                    .tracking(0.3)
                    .foregroundColor(.primary.opacity(0.9))
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
