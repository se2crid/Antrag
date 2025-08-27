//
//  ATAppRowView.swift
//  Antrag
//
//  Created by samara on 7.06.2025.
//

import SwiftUI
import IDeviceSwift

// MARK: - SwiftUI App Row View
struct ATAppRowView: View {
    let app: AppInfo
    @State private var iconImage: UIImage?
    private let padding: CGFloat = 14
    private let cornerRadius: CGFloat = 16
    
    var body: some View {
        HStack(spacing: padding * 0.93) {
            AsyncImage(url: nil) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                if let iconImage = iconImage {
                    Image(uiImage: iconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius * 0.6)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "app")
                                .foregroundColor(.secondary)
                        )
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius * 0.6))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius * 0.6)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.CFBundleDisplayName ?? app.CFBundleExecutable ?? "Unknown App")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Text("\(app.CFBundleShortVersionString ?? app.CFBundleVersion ?? "0") • \(app.CFBundleIdentifier ?? "")")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, padding * 1.04)
        .padding(.vertical, padding * 0.93)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
        )
        .contentShape(Rectangle())
        .task {
            await loadAppIcon()
        }
    }
    
    private func loadAppIcon() async {
        guard let identifier = app.CFBundleIdentifier else { return }
        
        do {
            let image = try await InstallationAppProxy.getAppIconCached(for: identifier)
            await MainActor.run {
                self.iconImage = image
            }
        } catch {
            // Icon loading failed, placeholder will be shown
        }
    }
}

// MARK: - Preview
#if DEBUG
struct ATAppRowView_Previews: PreviewProvider {
    static var previews: some View {
        ATAppRowView(app: AppInfo())
            .padding()
    }
}
#endif