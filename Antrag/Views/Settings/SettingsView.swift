//
//  SYSettingsView.swift
//  syslog
//
//  Created by samara on 17.05.2025.
//

import SwiftUI

// MARK: - View
struct SYSettingsView: View {
	private let _donationsUrl = "https://github.com/sponsors/khcrysalis"
	private let _githubUrl = "https://github.com/khcrysalis/Protokolle"
	
	// MARK: Body
	
	var body: some View {
		NavigationStack {
			Form {
				Section("Pairing") {
					NavigationLink("Tunnel & Pairing") {
						TunnelView()
					}
				}
				
				_feedback()
				_help()
			}
			.navigationTitle("Settings")
			.navigationBarTitleDisplayMode(.large)
		}
	}
}

// MARK: - View extension
extension SYSettingsView {

	@ViewBuilder
	private func _feedback() -> some View {
		Section {
			Button("GitHub Repository", systemImage: "safari") {
				UIApplication.open(_githubUrl)
			}
			Button("Support My Work", systemImage: "heart") {
				UIApplication.open(_donationsUrl)
			}
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
