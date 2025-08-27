//
//  ATSettingsView.swift
//  Antrag
//
//  Created by samara on 17.05.2025.
//

import SwiftUI

// MARK: - View
struct ATSettingsView: View {
	@AppStorage("AT.autoRefresh") private var autoRefresh: Bool = true
	@AppStorage("AT.refreshInterval") private var refreshInterval: Int = 30
	@AppStorage("AT.showSystemApps") private var showSystemAppsDefault: Bool = false
	@AppStorage("AT.confirmDelete") private var confirmDelete: Bool = true
	@AppStorage("AT.gridView") private var useGridView: Bool = false
	
	private let refreshIntervals = [15, 30, 60, 120, 300] // seconds
	private let _donationsUrl = "https://github.com/sponsors/khcrysalis"
	private let _githubUrl = "https://github.com/khcrysalis/Antrag"
	
	// MARK: Body
	
	var body: some View {
		NavigationStack {
			Form {
				Section("App Behavior") {
					Toggle("Auto Refresh", isOn: $autoRefresh)
					
					if autoRefresh {
						Picker("Refresh Interval", selection: $refreshInterval) {
							ForEach(refreshIntervals, id: \.self) { interval in
								Text("\(interval) seconds")
									.tag(interval)
							}
						}
					}
					
					Toggle("Show System Apps by Default", isOn: $showSystemAppsDefault)
					Toggle("Confirm Before Deleting", isOn: $confirmDelete)
				}
				
				Section("Display") {
					Toggle("Use Grid View", isOn: $useGridView)
				}
				
				Section("Connection") {
					NavigationLink("Tunnel & Pairing") {
						ATTunnelView()
					}
				}
				
				_about()
				_help()
			}
			.navigationTitle("Settings")
			.navigationBarTitleDisplayMode(.large)
		}
	}
}

// MARK: - View extension
extension ATSettingsView {
	@ViewBuilder
	private func _about() -> some View {
		Section("About") {
			NavigationLink(destination: SYAboutView()) {
				Label {
					Text("About \(Bundle.main.name)")
				} icon: {
					Image(uiImage: UIImage(named: Bundle.main.iconFileName ?? "")!)
						.appIconStyle(size: 23)
				}
			}
			Button("GitHub Repository", systemImage: "safari") {
				UIApplication.open(_githubUrl)
			}
			#if !DISTRIBUTION
			Button("Support My Work", systemImage: "heart") {
				UIApplication.open(_donationsUrl)
			}
			#endif
		}
	}
	
	@ViewBuilder
	private func _help() -> some View {
		Section("Help") {
			Button("Pairing File Guide", systemImage: "questionmark.circle") {
				UIApplication.open("https://github.com/StephenDev0/StikDebug-Guide/blob/main/pairing_file.md")
			}
			Button("Download StosVPN", systemImage: "arrow.down.app") {
				UIApplication.open("https://apps.apple.com/us/app/stosvpn/id6744003051")
			}
		}
	}
}
