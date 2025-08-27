//
//  ATAppsView.swift
//  Antrag
//
//  Created by samara on 27.08.2025.
//

import SwiftUI
import IDeviceSwift

// MARK: - Main View
struct ATAppsView: View {
    @StateObject private var viewModel = ATAppsViewModel()
    @State private var searchText = ""
    @State private var isEditMode = false
    @State private var selectedApps: Set<String> = []
    @State private var showingMassDeleteAlert = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("App Type", selection: $viewModel.appType) {
                    ForEach(ATAppsViewModel.AppType.allCases) { type in
                        Text(type.stringValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Apps List
                if viewModel.filteredApps.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Apps Found",
                        systemImage: "app.badge.fill",
                        description: Text("Please make sure you are connected to the VPN and have a pairing file.")
                    )
                } else {
                    List(selection: isEditMode ? $selectedApps : .constant(Set<String>())) {
                        ForEach(viewModel.filteredApps, id: \.CFBundleIdentifier) { app in
                            ATAppRowView(
                                app: app,
                                isEditMode: isEditMode,
                                onDelete: { await viewModel.deleteApp(app) }
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, isEditMode ? .constant(.active) : .constant(.inactive))
                }
            }
            .searchable(text: $searchText, prompt: "Search apps...")
            .onChange(of: searchText) { oldValue, newValue in
                viewModel.updateSearch(text: newValue)
            }
            .onChange(of: viewModel.appType) { oldValue, newValue in
                viewModel.filterApps()
            }
            .refreshable {
                await viewModel.reloadApps()
            }
            .navigationTitle("Apps")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await viewModel.reloadApps()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if !viewModel.filteredApps.isEmpty {
                            Button(isEditMode ? "Done" : "Select") {
                                withAnimation {
                                    isEditMode.toggle()
                                    if !isEditMode {
                                        selectedApps.removeAll()
                                    }
                                }
                            }
                        }
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear.circle.fill")
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if isEditMode && !selectedApps.isEmpty {
                        Button("Delete Selected (\(selectedApps.count))") {
                            showingMassDeleteAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Delete Apps", isPresented: $showingMassDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteSelectedApps(selectedApps)
                        selectedApps.removeAll()
                        isEditMode = false
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(selectedApps.count) app(s)? This action cannot be undone.")
            }
            .sheet(isPresented: $showingSettings) {
                ATSettingsView()
            }
            .task {
                await viewModel.loadAppsIfNeeded()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading apps...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }
}

// MARK: - App Row View
struct ATAppRowView: View {
    let app: AppInfo
    let isEditMode: Bool
    let onDelete: () async -> Void
    @State private var showingAppInfo = false
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            AppIconAsyncImage(
                bundleIdentifier: app.CFBundleIdentifier ?? "",
                size: 52
            )
            
            // App Info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.CFBundleDisplayName ?? "Unknown App")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                Text(app.CFBundleIdentifier ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if !isEditMode {
                // Context Menu for actions
                Menu {
                    Button {
                        if let bundleId = app.CFBundleIdentifier {
                            UIApplication.openApp(with: bundleId)
                        }
                    } label: {
                        Label("Open", systemImage: "arrow.up.forward")
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await onDelete()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.quaternarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditMode {
                showingAppInfo = true
            }
        }
        .sheet(isPresented: $showingAppInfo) {
            ATAppInfoView(app: app)
        }
    }
}

// MARK: - View Model
@MainActor
class ATAppsViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var filteredApps: [AppInfo] = []
    @Published var appType: AppType = .user
    @Published var isLoading = false
    
    private var searchText = ""
    private var hasLoaded = false
    
    enum AppType: String, CaseIterable, Identifiable {
        case system = "System"
        case user = "User"
        
        var id: String { rawValue }
        
        var stringValue: String {
            .localized(rawValue)
        }
    }
    
    private var appsManager: InstallationAppProxy {
        let manager = InstallationAppProxy()
        manager.delegate = self
        return manager
    }
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .heartbeat,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.loadAppsIfNeeded()
            }
        }
    }
    
    func loadAppsIfNeeded() async {
        guard !hasLoaded else { return }
        await loadApps()
    }
    
    func reloadApps() async {
        hasLoaded = false
        HeartbeatManager.shared.start(true)
        await loadApps()
    }
    
    private func loadApps() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        isLoading = true
        
        do {
            try await appsManager.listApps()
        } catch {
            // Handle error
            print("Error loading apps: \(error)")
            isLoading = false
        }
    }
    
    func updateSearch(text: String) {
        searchText = text
        filterApps()
    }
    
    func filterApps() {
        var filtered = apps.filter { app in
            let typeMatches = (appType == .system && app.ApplicationType == "System") ||
                             (appType == .user && app.ApplicationType != "System")
            
            guard typeMatches else { return false }
            
            if searchText.isEmpty {
                return true
            }
            
            let searchLower = searchText.lowercased()
            return app.CFBundleDisplayName?.lowercased().contains(searchLower) == true ||
                   app.CFBundleExecutable?.lowercased().contains(searchLower) == true ||
                   app.CFBundleIdentifier?.lowercased().contains(searchLower) == true
        }
        
        filteredApps = filtered.sorted { ($0.CFBundleDisplayName ?? "") < ($1.CFBundleDisplayName ?? "") }
    }
    
    func deleteApp(_ app: AppInfo) async {
        guard let bundleId = app.CFBundleIdentifier else { return }
        
        do {
            try await InstallationAppProxy.deleteApp(for: bundleId)
            
            // Remove from local arrays
            apps.removeAll { $0.CFBundleIdentifier == bundleId }
            filterApps()
        } catch {
            print("Error deleting app: \(error)")
            // TODO: Show error alert
        }
    }
    
    func deleteSelectedApps(_ selectedIds: Set<String>) async {
        for bundleId in selectedIds {
            guard let app = apps.first(where: { $0.CFBundleIdentifier == bundleId }) else { continue }
            await deleteApp(app)
        }
    }
}

// MARK: - ViewModel Extension
extension ATAppsViewModel: InstallationAppProxyDelegate {
    func installationAppProxy(_ proxy: InstallationAppProxy, didReceiveApps apps: [AppInfo]) {
        self.apps = apps
        filterApps()
        isLoading = false
    }
    
    func installationAppProxy(_ proxy: InstallationAppProxy, didFailWithError error: Error) {
        isLoading = false
        print("Installation proxy error: \(error)")
        // TODO: Show error alert
    }
}