//
//  AppsViewModel.swift
//  caipirinha
//
//  Created by samara on 28.05.2025.
//


import SwiftUI

class AppsViewModel: ObservableObject {
	@Published var apps: [AppInfo] = []
	@Published var systemApps: [AppInfo] = []
	
	func updateApps(from dicts: [AppInfo], using type: AppType = .user) {
		if type == .user {
			apps = dicts
		} else if type == .system {
			systemApps = dicts
		}
	}
}

final class AppIconCache: ObservableObject {
	static let shared = AppIconCache()
	private init() {}
	
	@Published private var cache: [String: UIImage] = [:]
	
	func image(for bundleId: String) -> UIImage? {
		cache[bundleId]
	}
	
	func setImage(_ image: UIImage, for bundleId: String) {
		cache[bundleId] = image
	}
}
