//
//  AppsDetailView.swift
//  caipirinha
//
//  Created by samara on 28.05.2025.
//

import SwiftUI

// MARK: - View
struct AppsDetailView: View {
	var app: AppInfo
	
	// MARK: Body
    var body: some View {
		Form {
			Section {
				if let name = app.cfBundleName, !name.isEmpty {
					LabeledContent("Name", value: name).copyableText(name)
				}
				if let bundleId = app.cfBundleIdentifier, !bundleId.isEmpty {
					LabeledContent("Bundle Identifier", value: bundleId).copyableText(bundleId)
				}
				if let type = app.applicationType, !type.isEmpty {
					LabeledContent("Type", value: type).copyableText(type)
				}
			}

			
			Section {
				if let version = app.cfBundleShortVersionString, !version.isEmpty {
					LabeledContent("Application Version", value: version).copyableText(version)
				}
				if let build = app.cfBundleVersion, !build.isEmpty {
					LabeledContent("Application Build", value: build).copyableText(build)
				}
				if let sdkVersion = app.dtPlatformVersion, !sdkVersion.isEmpty {
					LabeledContent("SDK Version Built with", value: sdkVersion).copyableText(sdkVersion)
				}
				if let minOSVersion = app.minimumOSVersion, !minOSVersion.isEmpty {
					LabeledContent("Minimum iOS Version Required", value: minOSVersion).copyableText(minOSVersion)
				}
			}
			
			Section {
				if let signer = app.signerIdentity, !signer.isEmpty {
					LabeledContent("Signed by", value: signer).copyableText(signer)
				}
			}
			
			Section {
				if let i = app.entitlements {
					NavigationLink("Entitlements") {
						AppsDetailsAnyView(title: "Entitlements", entitlements: i)
					}
				}
				
				if let i = app.cfBundleIcons {
					NavigationLink("Icons") {
						AppsDetailsAnyView(title: "Icons", entitlements: i)
					}
				}
				
				if let i = app.uiApplicationSceneManifest {
					NavigationLink("Scene Manifest") {
						AppsDetailsAnyView(title: "Scene Manifest", entitlements: i)
					}
				}
			}
			
			Section {
				if let path = app.path, !path.isEmpty {
					_subtitleContent("Bundle Path", value: path).copyableText(path)
				}
				if let path = app.container, !path.isEmpty {
					_subtitleContent("Container Path", value: path).copyableText(path)
				}
			}
		}
		.navigationTitle(app.cfBundleName ?? "")
		.onAppear {
			dump(app)
		}
    }
	
	@ViewBuilder
	private func _subtitleContent(_ title: String, value: String) -> some View {
		VStack(alignment: .leading) {
			Text(title)
				.font(.headline)
				.fontWeight(.regular)
			Text(value)
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
	}
}
