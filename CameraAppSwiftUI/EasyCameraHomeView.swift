//
//  EasyCameraHomeView.swift
//  CameraAppSwiftUI
//
//  Created by MacBook Air M1 on 21/11/25.
//

import SwiftUI

import SwiftUI

// MARK: - Model

struct BlogPost: Identifiable, Codable {
    let id: Int
    let title: String
    let subtitle: String
    let readTime: Int
    let body: String
}


// MARK: - Store

final class BlogStore: ObservableObject {
    @Published var posts: [BlogPost] = []

    init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "blogs", withExtension: "json") else {
            print("⚠️ blogs.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([BlogPost].self, from: data)
            DispatchQueue.main.async {
                self.posts = decoded
            }
        } catch {
            print("⚠️ Failed to decode blogs.json:", error)
        }
    }
}


struct EasyCameraHomeView: View {
    @StateObject private var blogStore = BlogStore()
    @State private var showCamera = false
    @State private var showSetting = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack{
                    // MARK: - Blog List
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(blogStore.posts) { post in
                                NavigationLink {
                                    BlogDetailView(post: post)
                                } label: {
                                    BlogRow(post: post)
                                }
                                .buttonStyle(.plain)   // so it looks like a card, not a blue button
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Divider()
                        Button {
                            showCamera = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Open Pro Camera")
                                        .font(.headline)
                                    Text("Start shooting with Easy camara")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.subheadline)
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
                .navigationTitle("Easy camara")
                .toolbar {
                    // Optional: small camera icon in the top bar
                    ToolbarItem(placement: .topBarTrailing) {
//                        Button {
//                            showSetting = true
//                        } label: {
                           // Image(systemName: "gearshape.fill")
                      //  NavigationLink(value: <#T##P?#>, label: <#T##() -> Label#>)
                        
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                       // }
                    }
                }

                // MARK: - Bottom Camera Button
            
            }
        }
//        .fullScreenCover(isPresented: $showSetting) {
//            // This is your existing camera screen
//            SettingsView()
//              //  .ignoresSafeArea()
//        }
        .fullScreenCover(isPresented: $showCamera) {
            // This is your existing camera screen
            CameraRootView()
              //  .ignoresSafeArea()
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

                Text(post.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

import SwiftUI

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
//                    // Header Image
//                    if let imageName = post.featuredImage {
//                        Image(imageName)
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(height: geometry.size.width * 0.6)
//                            .clipped()
//                            .overlay(
//                                LinearGradient(
//                                    colors: [.clear, .black.opacity(0.3)],
//                                    startPoint: .center,
//                                    endPoint: .bottom
//                                )
//                            )
//                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // Meta information
                        VStack(alignment: .leading, spacing: 16) {
//                            HStack(spacing: 12) {
//                                //PillView(text: post.category, color: .blue)
//                                PillView(text: "\(post.readTime) min read", color: .gray)
//                            }
//                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text(post.title)
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text(post.subtitle)
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
//                            HStack(spacing: 16) {
//                                HStack(spacing: 6) {
//                                    Image(systemName: "person.circle.fill")
//                                        .foregroundColor(.secondary)
//                                    Text(post.author)
//                                        .font(.subheadline)
//                                        .foregroundColor(.secondary)
//                                }
//                                
//                                HStack(spacing: 6) {
//                                    Image(systemName: "calendar")
//                                        .foregroundColor(.secondary)
//                                    Text(formatDate(post.publishDate))
//                                        .font(.subheadline)
//                                        .foregroundColor(.secondary)
//                                }
//                            }
                        }
                        .padding(.top, 24)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Content
                        EnhancedMarkdownText(text: post.body)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear
                                .onAppear {
                                    updateScrollOffset(contentGeometry: contentGeometry, geometry: geometry)
                                }
                                .onChange(of: contentGeometry.frame(in: .global).minY) { _ in
                                    updateScrollOffset(contentGeometry: contentGeometry, geometry: geometry)
                                }
                        }
                    )
                }
            }
          //  .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        // Share action
//                    }) {
//                        Image(systemName: "square.and.arrow.up")
//                            .font(.system(size: 16, weight: .medium))
//                    }
//                }
//            }
//            .overlay(
//                NavigationBarOverlay(
//                    title: post.title,
//                    opacity: navigationBarOpacity
//                )
//            )
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
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

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
            } else {
                Text(text)
                    .font(.system(.body, design: .serif))
                    .lineSpacing(8)
                    .tracking(0.3)
                    .foregroundColor(.primary.opacity(0.9))
            }
        }
    }
}

// Alternative with more customization for different elements
struct CustomMarkdownText: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // You could parse and render different markdown elements manually
            // for even more control over styling
            Text(text)
                .font(.system(.body, design: .rounded))
                .lineSpacing(10)
                .tracking(0.2)
                .foregroundColor(.primary.opacity(0.85))
                .background(
                    LinearGradient(
                        colors: [.clear, .blue.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}

struct PremiumBodyText: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            if let attributed = try? AttributedString(
                markdown: text,
                options: .init(interpretedSyntax: .full)
            ) {
                Text(attributed)
                    .font(.system(.title3, design: .serif))
                    .lineSpacing(14)
                    .tracking(0.4)
                    .foregroundColor(.primary.opacity(0.75))
                    .blendMode(.multiply)
            }
        }
        .padding(.vertical, 16)
        .overlay(
            // Reading guide lines
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .blue.opacity(0.01),
                            .blue.opacity(0.02),
                            .blue.opacity(0.01),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .background(
            // Subtle texture background
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
                )
                .padding(.horizontal, -8)
        )
    }
}

// Ultra luxury reading experience
struct LuxuryBodyText: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            if let attributed = try? AttributedString(markdown: text) {
                Text(attributed)
                    .font(.system(size: 19, weight: .regular, design: .serif))
                    .lineSpacing(16)
                    .tracking(0.5)
                    .foregroundColor(.primary.opacity(0.7))
                    .background(
                        GeometryReader { geometry in
                            // Reading line guides
                            Path { path in
                                let lineHeight: CGFloat = 14
                                let numberOfLines = Int(geometry.size.height / lineHeight)
                                
                                for i in 0..<numberOfLines {
                                    let y = CGFloat(i) * lineHeight + 8
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                                }
                            }
                            .stroke(Color.orange.opacity(0.08), lineWidth: 0.5)
                        }
                    )
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 4)
        .background(
            // Book-like background
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                // Subtle paper texture
                Image(systemName: "line.3.crossed.swirl.circle.fill")
                    .foregroundColor(.primary.opacity(0.02))
                    .font(.system(size: 200))
                    .rotationEffect(.degrees(30))
                    .offset(x: 50, y: 100)
            )
        )
    }
}

// Modern minimalist approach
struct ModernBodyText: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            if let attributed = try? AttributedString(markdown: text) {
                Text(attributed)
                    .font(.system(.body, design: .default))
                    .lineSpacing(12)
                    .tracking(0.3)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                .primary.opacity(0.9),
                                .primary.opacity(0.8),
                                .primary.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .padding(.vertical, 20)
        .background(
            // Modern card background
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal, -16)
        )
    }
}

// Best overall - combines all the good elements
struct UltimateBodyText: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            if let attributed = try? AttributedString(markdown: text) {
                Text(attributed)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .lineSpacing(15)
                    .tracking(0.45)
                    .foregroundColor(.primary.opacity(0.75))
                    .blendMode(.multiply)
                    .background(
                        // Reading focus highlight
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.03))
                            .padding(.horizontal, -8)
                            .padding(.vertical, -2)
                    )
            }
        }
        .padding(.vertical, 20)
        .overlay(
            // Top and bottom fade
            VStack {
                LinearGradient(
                    colors: [Color(.systemBackground).opacity(0.9), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
                Spacer()
                LinearGradient(
                    colors: [.clear, Color(.systemBackground).opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
            }
        )
    }
}

import SwiftUI
import MessageUI

struct SettingsView: View {
    private let phoneNumber = "+8801904993197"
    private let email = "sohagswift@gmail.com"

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

                Section("About") {
                    HStack {
                        Text("App")
                        Spacer()
                        Text("Easy camara")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showMessageComposer) {
                MessageComposer(
                    recipients: [phoneNumber],
                    body: "Hi Sohag,\n\nI am using Easy camara and…"
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
        let subject = "Easy camara feedback"
        let body = "Hi Sohag,\n\nI am using Easy camara and…"
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
