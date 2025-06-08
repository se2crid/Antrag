//
//  ATAppsViewController+update.swift
//  Antrag
//
//  Created by samara on 7.06.2025.
//

import UIKit
import IDeviceSwift

// MARK: - Class extension: delegate
extension ATAppsViewController: InstallationProxyAppsDelegate {
	func updateApplications(with apps: [IDeviceSwift.AppInfo]) {
		self.apps = apps
		filterAndReload()
	}
	
	func filterAndReload() {
		filteredApps = apps
			.filter {
				switch appType {
				case .system: return $0.ApplicationType == "System"
				case .user: return $0.ApplicationType == "User"
				}
			}
			.sorted {
				let name1 = $0.CFBundleDisplayName ?? $0.CFBundleExecutable ?? ""
				let name2 = $1.CFBundleDisplayName ?? $0.CFBundleExecutable ?? ""
				let result = name1.localizedCaseInsensitiveCompare(name2)
				return result == .orderedAscending
			}
		
		tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
	}

}
