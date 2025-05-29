//
//  SettingsTunnelView.swift
//  Feather (idevice)
//
//  Created by samara on 29.04.2025.
//

import SwiftUI

// MARK: - View
struct TunnelView: View {
	@State private var _isImportingPairingPresenting = false
	
	@State var doesHavePairingFile = false
	
	// MARK: Body
    var body: some View {
		List {
			Section {
				_tunnelInfo()
				TunnelHeaderView()
			} footer: {
				if doesHavePairingFile {
					Text("Seems like you've gotten your hands on your pairing file!")
				} else {
					Text("No pairing file found, please import it.")
				}
			}
			
			Section {
				Button("Import Pairing File", systemImage: "square.and.arrow.down") {
					_isImportingPairingPresenting = true
				}
				Button("Restart Heartbeat", systemImage: "arrow.counterclockwise") {
					HeartbeatManager.shared.start(true)
					
					DispatchQueue.global(qos: .userInitiated).async {
						if !HeartbeatManager.shared.checkSocketConnection().isConnected {
							DispatchQueue.main.async {
								UIAlertController.showAlertWithOk(
									title: "Socket",
									message: "Unable to connect to TCP. Make sure you have loopback VPN enabled and you are on WiFi or Airplane mode."
								)
							}
						}
					}
				}
			}
			
			Section("Help") {
				Button("Pairing File Guide", systemImage: "questionmark.circle") {
					UIApplication.open("https://github.com/StephenDev0/StikDebug-Guide/blob/main/pairing_file.md")
				}
				Button("Download StosVPN", systemImage: "arrow.down.app") {
					UIApplication.open("https://apps.apple.com/us/app/stosvpn/id6744003051")
				}
			}
		}
		.navigationTitle("Tunnel & Pairing")
		.sheet(isPresented: $_isImportingPairingPresenting) {
			FileImporterRepresentableView(
				allowedContentTypes:  [.xmlPropertyList, .plist, .mobiledevicepairing],
				onDocumentsPicked: { urls in
					guard let selectedFileURL = urls.first else { return }
					movePairing(selectedFileURL)
					doesHavePairingFile = true
				}
			)
		}
		.onAppear {
			doesHavePairingFile = FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile())
			? true
			: false
		}
    }
	
	@ViewBuilder
	private func _tunnelInfo() -> some View {
		HStack {
			VStack(alignment: .leading, spacing: 6) {
				Text("Heartbeat")
					.font(.headline)
				Text("The heartbeat is activated in the background, it will restart when the app is re-opened or prompted. If the status below is pulsing, that means its healthy.")
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
		}
	}
	
	func movePairing(_ url: URL) {
		let fileManager = FileManager.default
		let dest = URL.documentsDirectory.appendingPathComponent("pairingFile.plist")
		
		try? fileManager.removeItem(at: dest)
		try? fileManager.copyItem(at: url, to: dest)
		
		HeartbeatManager.shared.start(true)
	}
}
