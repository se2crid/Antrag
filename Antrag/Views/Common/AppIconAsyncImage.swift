//
//  AppIconAsyncImage.swift
//  Antrag
//
//  Created by samara on 27.08.2025.
//

import SwiftUI
import IDeviceSwift

// MARK: - App Icon Async Image
struct AppIconAsyncImage: View {
    let bundleIdentifier: String
    let size: CGFloat
    
    @State private var appIcon: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let appIcon = appIcon {
                Image(uiImage: appIcon)
                    .resizable()
            } else if isLoading {
                RoundedRectangle(cornerRadius: size * 0.2337)
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
            } else {
                RoundedRectangle(cornerRadius: size * 0.2337)
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "app.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: size * 0.4))
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2337))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.2337)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .task {
            await loadAppIcon()
        }
    }
    
    private func loadAppIcon() async {
        do {
            let icon = try await InstallationAppProxy.getAppIconCached(for: bundleIdentifier)
            await MainActor.run {
                self.appIcon = icon
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}