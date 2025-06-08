//
//  SYSettingsView.swift
//  syslog
//
//  Created by samara on 17.05.2025.
//

import SwiftUI

// MARK: - View
struct ATSettingsView: View {
	private let _donationsUrl = "https://github.com/sponsors/khcrysalis"
	private let _githubUrl = "https://github.com/khcrysalis/Antrag"
	
	// MARK: Body
	
	var body: some View {
		NavigationStack {
			Form {
				Section(.localized("Pairing")) {
					NavigationLink(.localized("Tunnel & Pairing")) {
						ATTunnelView()
					}
				}
				
				_feedback()
				_help()
			}
			.navigationTitle(.localized("Settings"))
			.navigationBarTitleDisplayMode(.large)
		}
	}
}

// MARK: - View extension
extension ATSettingsView {

	@ViewBuilder
	private func _feedback() -> some View {
		Section {
			Button(.localized("GitHub Repository"), systemImage: "safari") {
				UIApplication.open(_githubUrl)
			}
			Button(.localized("Support My Work"), systemImage: "heart") {
				UIApplication.open(_donationsUrl)
			}
		}
	}
	
	@ViewBuilder
	private func _help() -> some View {
		Section(.localized("Help")) {
			Button(.localized("Pairing File Guide"), systemImage: "questionmark.circle") {
				UIApplication.open("https://github.com/StephenDev0/StikDebug-Guide/blob/main/pairing_file.md")
			}
			Button(.localized("Download StosVPN"), systemImage: "arrow.down.app") {
				UIApplication.open("https://apps.apple.com/us/app/stosvpn/id6744003051")
			}
		}
	}
}
