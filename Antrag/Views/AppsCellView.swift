//
//  AppsCellView.swift
//  caipirinha
//
//  Created by samara on 28.05.2025.
//


import SwiftUI

struct AppsCellView: View {
	let app: AppInfo
	@State private var iconImage: UIImage? = nil
	@State private var isLoading = false
	@ObservedObject private var iconCache = AppIconCache.shared
	@ObservedObject var viewModel: AppsViewModel
	
	var body: some View {
		HStack {
			if let uiImage = iconImage {
				Image(uiImage: uiImage)
					.resizable()
					.frame(width: 40, height: 40)
					.cornerRadius(6)
			} else if isLoading {
				ProgressView()
					.frame(width: 40, height: 40)
			}
			
			VStack(alignment: .leading) {
				Text(app.cfBundleName ?? "Unknown App")
					.font(.headline)
				Text(app.cfBundleIdentifier ?? "No bundle ID")
					.font(.subheadline)
					.foregroundColor(.gray)
			}
		}
		.contextMenu {
			if let id = app.cfBundleIdentifier {
				Button("Open", systemImage: "app.badge.checkmark") {
					UIApplication.openApp(with: id)
				}
			}
		}
		.swipeActions {
			if let id = app.cfBundleIdentifier {
				Button("delete", role: .destructive) {
					delete(for: id)
				}
			}
		}
		.onAppear {
			guard let bundleId = app.cfBundleIdentifier else { return }
			
			if let cachedImage = iconCache.image(for: bundleId) {
				iconImage = cachedImage
				return
			}
			
			isLoading = true
			
			Task {
				do {
					let icon = try await ListApps.getAppIcon(for: bundleId)
					guard let icon else {
						await MainActor.run { isLoading = false }
						return
					}
					iconCache.setImage(icon, for: bundleId)
					await MainActor.run {
						iconImage = icon
						isLoading = false
					}
				} catch {
					await MainActor.run { isLoading = false }
				}
			}

		}
	}
	
	func delete(for id: String) {
		Task {
			do {
				try await ListApps.deleteApp(for: id)
				try await ListApps(viewModel: viewModel).listApps()
			} catch {
				await MainActor.run {
					UIAlertController.showAlertWithOk(
						title: "Error",
						message: error.localizedDescription,
						action: {
							HeartbeatManager.shared.start(true)
						}
					)
				}
			}
		}
	}
}
