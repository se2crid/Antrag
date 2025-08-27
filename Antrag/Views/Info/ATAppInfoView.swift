//
//  ATAppInfoView.swift
//  Antrag
//
//  Created by samara on 27.08.2025.
//

import SwiftUI
import IDeviceSwift

// MARK: - App Info View
struct ATAppInfoView: View {
    let app: AppInfo
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    private var infoSections: [[LabeledInfo]] {
        buildInfoSections()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Header Section
                headerSection
                
                // Info Sections
                ForEach(Array(infoSections.enumerated()), id: \.offset) { index, section in
                    Section {
                        ForEach(Array(section.enumerated()), id: \.offset) { _, info in
                            HStack {
                                Text(info.title)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(info.value)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
            }
            .navigationTitle("App Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if app.CFBundleIdentifier != nil {
                        Menu {
                            Button {
                                if let bundleId = app.CFBundleIdentifier {
                                    UIApplication.openApp(with: bundleId)
                                }
                            } label: {
                                Label("Open App", systemImage: "arrow.up.forward")
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete App", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Delete App", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteApp()
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(app.CFBundleDisplayName ?? "this app")? This action cannot be undone.")
            }
        }
        .task {
            // No longer need to manually load app icon
        }
    }
    
    private var headerSection: some View {
        Section {
            HStack {
                // App Icon
                AppIconAsyncImage(
                    bundleIdentifier: app.CFBundleIdentifier ?? "",
                    size: 80
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.CFBundleDisplayName ?? "Unknown App")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(app.CFBundleIdentifier ?? "")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let version = app.CFBundleShortVersionString {
                        Text("Version \(version)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private func deleteApp() async {
        guard let bundleId = app.CFBundleIdentifier else { return }
        
        do {
            try await InstallationAppProxy.deleteApp(for: bundleId)
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Failed to delete app: \(error)")
            // TODO: Show error alert
        }
    }
}

// MARK: - Helper Types
struct LabeledInfo {
    let title: String
    let value: String
}

// MARK: - Info Building Extension
extension ATAppInfoView {
    private func buildInfoSections() -> [[LabeledInfo]] {
        var sections: [[LabeledInfo]] = []
        
        // Basic Info Section
        var basicInfo: [LabeledInfo] = []
        
        if let name = app.CFBundleDisplayName {
            basicInfo.append(LabeledInfo(title: "Display Name", value: name))
        }
        
        if let executable = app.CFBundleExecutable {
            basicInfo.append(LabeledInfo(title: "Executable", value: executable))
        }
        
        if let identifier = app.CFBundleIdentifier {
            basicInfo.append(LabeledInfo(title: "Bundle Identifier", value: identifier))
        }
        
        if let version = app.CFBundleShortVersionString {
            basicInfo.append(LabeledInfo(title: "Version", value: version))
        }
        
        if let buildVersion = app.CFBundleVersion {
            basicInfo.append(LabeledInfo(title: "Build Version", value: buildVersion))
        }
        
        if let appType = app.ApplicationType {
            basicInfo.append(LabeledInfo(title: "Application Type", value: appType))
        }
        
        if !basicInfo.isEmpty {
            sections.append(basicInfo)
        }
        
        // Technical Info Section
        var technicalInfo: [LabeledInfo] = []
        
        if let minimumOS = app.MinimumOSVersion {
            technicalInfo.append(LabeledInfo(title: "Minimum OS Version", value: minimumOS))
        }
        
        if let platformVersion = app.DTPlatformVersion {
            technicalInfo.append(LabeledInfo(title: "Platform Version", value: platformVersion))
        }
        
        if let sdkVersion = app.DTSDKBuild {
            technicalInfo.append(LabeledInfo(title: "SDK Build", value: sdkVersion))
        }
        
        if let architectures = app.UIRequiredDeviceCapabilities {
            technicalInfo.append(LabeledInfo(title: "Required Capabilities", value: architectures.joined(separator: ", ")))
        }
        
        if !technicalInfo.isEmpty {
            sections.append(technicalInfo)
        }
        
        // Permissions Section (if applicable)
        var permissionsInfo: [LabeledInfo] = []
        
        if let entitlements = app.Entitlements {
            for (key, value) in entitlements {
                if key.contains("privacy") || key.contains("permission") || key.contains("usage") {
                    permissionsInfo.append(LabeledInfo(title: key, value: "\(value)"))
                }
            }
        }
        
        if !permissionsInfo.isEmpty {
            sections.append(permissionsInfo)
        }
        
        return sections
    }
}