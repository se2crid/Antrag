//
//  ATAppsView.swift
//  Antrag
//
//  Created by samara on 7.06.2025.
//

import SwiftUI
import IDeviceSwift

// MARK: - SwiftUI Apps View
struct ATAppsView: View {
    @StateObject private var appsManager = AppsManager()
    @State private var appType: AppType = .user
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var selectedApp: AppInfo?
    
    // MARK: - App Type Enum
    enum AppType: String, CaseIterable, Identifiable {
        case system = "System"
        case user = "User"
        
        var id: String {
            rawValue
        }
        
        var stringValue: String {
            .localized(rawValue)
        }
    }
    
    // Computed properties for filtered and sorted apps
    private var filteredApps: [AppInfo] {
        let typeFiltered = appsManager.apps.filter { app in
            // Safety check: ensure ApplicationType is not nil
            guard let appType = app.ApplicationType else { return false }
            
            switch self.appType {
            case .system: return appType == "System"
            case .user: return appType == "User"
            }
        }
        
        if searchText.isEmpty {
            return typeFiltered.sorted { app1, app2 in
                let name1 = app1.CFBundleDisplayName ?? app1.CFBundleExecutable ?? ""
                let name2 = app2.CFBundleDisplayName ?? app2.CFBundleExecutable ?? ""
                return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
            }
        } else {
            let lowercasedSearch = searchText.lowercased()
            return typeFiltered.filter { app in
                (app.CFBundleDisplayName?.lowercased().contains(lowercasedSearch) == true) ||
                (app.CFBundleExecutable?.lowercased().contains(lowercasedSearch) == true) ||
                (app.CFBundleIdentifier?.lowercased().contains(lowercasedSearch) == true)
            }.sorted { app1, app2 in
                let name1 = app1.CFBundleDisplayName ?? app1.CFBundleExecutable ?? ""
                let name2 = app2.CFBundleDisplayName ?? app2.CFBundleExecutable ?? ""
                return name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom segmented control
                Picker("App Type", selection: $appType) {
                    ForEach(AppType.allCases) { type in
                        Text(type.stringValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Apps list
                if filteredApps.isEmpty && !appsManager.isLoading {
                    ContentUnavailableView {
                        Label("No Apps Found", systemImage: "nosign.app")
                    } description: {
                        Text("Please make sure you are connected to the VPN and have a pairing file.")
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    List {
                        ForEach(filteredApps, id: \.CFBundleIdentifier) { app in
                            ATAppRowView(app: app)
                                .listRowInsets(EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    // Delete action
                                    if let identifier = app.CFBundleIdentifier {
                                        Button(role: .destructive) {
                                            Task {
                                                await deleteApp(identifier: identifier)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                        
                                        // Open action
                                        Button {
                                            UIApplication.openApp(with: identifier)
                                        } label: {
                                            Label("Open", systemImage: "arrow.up.forward")
                                        }
                                        .tint(.blue)
                                    }
                                }
                                .onTapGesture {
                                    selectedApp = app
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await appsManager.reloadApps()
                    }
                    .background(.ultraThinMaterial.opacity(0.3))
                }
            }
            .navigationTitle("Apps")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search apps...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await appsManager.reloadApps()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    ATSettingsView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingSettings = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
            .sheet(item: $selectedApp) { app in
                NavigationStack {
                    ATAppInfoViewWrapper(app: app)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    selectedApp = nil
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: filteredApps.count)
        .task {
            await appsManager.loadAppsInitially()
        }
        .onReceive(NotificationCenter.default.publisher(for: .heartbeat)) { _ in
            Task {
                await appsManager.loadAppsIfNeeded()
            }
        }
    }
    
    // MARK: - Actions
    
    private func deleteApp(identifier: String) async {
        do {
            try await InstallationAppProxy.deleteApp(for: identifier)
            await appsManager.removeApp(identifier: identifier)
            
            // Provide haptic feedback
            await MainActor.run {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        } catch {
            await MainActor.run {
                // Show error alert
                UIAlertController.showAlertWithOk(
                    title: nil,
                    message: error.localizedDescription
                )
            }
        }
    }
}

// MARK: - Apps Manager ObservableObject
@MainActor
class AppsManager: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var isLoading = false
    private var didLoad = false
    
    private var appsProxy: InstallationAppProxy {
        let proxy = InstallationAppProxy()
        proxy.delegate = self
        return proxy
    }
    
    func loadAppsInitially() async {
        guard !didLoad else { return }
        await loadApps()
    }
    
    func loadAppsIfNeeded() async {
        guard !didLoad else { return }
        await loadApps()
    }
    
    func reloadApps() async {
        didLoad = false
        HeartbeatManager.shared.start(true)
        await loadApps()
    }
    
    private func loadApps() async {
        guard !didLoad else { return }
        didLoad = true
        
        do {
            isLoading = true
            try await appsProxy.listApps()
        } catch {
            isLoading = false
            UIAlertController.showAlertWithOk(
                title: nil,
                message: error.localizedDescription,
                action: {
                    HeartbeatManager.shared.start(true)
                }
            )
        }
    }
    
    func removeApp(identifier: String) async {
        apps.removeAll { $0.CFBundleIdentifier == identifier }
    }
}

// MARK: - Apps Manager Delegate
extension AppsManager: InstallationProxyAppsDelegate {
    func updateApplications(with apps: [AppInfo]) {
        self.apps = apps
        self.isLoading = false
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - AppInfo Identifiable Extension
extension AppInfo: Identifiable {
    public var id: String {
        CFBundleIdentifier ?? CFBundleDisplayName ?? CFBundleExecutable ?? UUID().uuidString
    }
}

// MARK: - Wrapper for UIKit View Controller
struct ATAppInfoViewWrapper: UIViewControllerRepresentable {
    let app: AppInfo
    
    func makeUIViewController(context: Context) -> ATAppInfoViewController {
        return ATAppInfoViewController(app: app)
    }
    
    func updateUIViewController(_ uiViewController: ATAppInfoViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview
#if DEBUG
struct ATAppsView_Previews: PreviewProvider {
    static var previews: some View {
        ATAppsView()
    }
}
#endif