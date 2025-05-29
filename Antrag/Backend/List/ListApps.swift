//
//  ListApps.swift
//  caipirinha
//
//  Created by samara on 28.05.2025.
//

import Foundation
import SwiftUICore
import UIKit

enum AppType: String, CaseIterable, Identifiable {
	case system = "System"
	case user = "User"
	
	var id: String { rawValue }
}

class ListApps: NSObject {
	private let _heartbeat = HeartbeatManager.shared
	
	typealias InstallationProxyClientHandle = OpaquePointer
	typealias SpringBoardServicesClientHandle = OpaquePointer
	
	@ObservedObject var viewModel: AppsViewModel
	
	init(viewModel: AppsViewModel = AppsViewModel()) {
		self.viewModel = viewModel
	}

	func listApps(type: AppType = .user) async throws {
		var installproxy: InstallationProxyClientHandle?
		
		let allApps = try await Task.detached(priority: .userInitiated) { () -> [AppInfo] in
			guard FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile()) else {
				throw ListAppsError.err
			}
			
			guard await self._heartbeat.checkSocketConnection().isConnected else {
				throw ListAppsError.err
			}
			
			guard await installation_proxy_connect_tcp(self._heartbeat.provider, &installproxy) == IdeviceSuccess else {
				throw ListAppsError.err
			}
			
			let applicationType = type.rawValue
			var outResult: UnsafeMutableRawPointer?
			var outResultLen: Int = 0
			
			guard installation_proxy_get_apps(installproxy, applicationType, nil, 0, &outResult, &outResultLen) == IdeviceSuccess else {
				throw ListAppsError.err
			}
			
			var appInfos: [AppInfo] = []
			let decoder = PropertyListDecoder()

			if let outResult = outResult {
				let buffer = outResult.bindMemory(to: OpaquePointer?.self, capacity: outResultLen)
				let pointerBuffer = UnsafeBufferPointer(start: buffer, count: outResultLen)
				
				let appPlists = Array(pointerBuffer)
				for plist in appPlists {
					guard let plist = plist else { continue }
					
					var xml: UnsafeMutablePointer<CChar>?
					var length: UInt32 = 0
					
					plist_to_xml(UnsafeMutableRawPointer(plist), &xml, &length)
					
					if let xml = xml {
						let data = Data(bytes: xml, count: Int(length))
						do {
							let appInfo = try decoder.decode(AppInfo.self, from: data)
							appInfos.append(appInfo)
						} catch {
							print("Failed to decode AppInfo plist: \(error)")
						}
						free(xml)
					}
				}
			}
			
			installation_proxy_client_free(installproxy)
			
			return appInfos
		}.value
		
		await MainActor.run {
			self.viewModel.updateApps(from: allApps, using: type)
		}
	}
	
	static func getAppIcon(for id: String) async throws -> UIImage? {
		var springServices: SpringBoardServicesClientHandle?
		
		return try await Task.detached(priority: .userInitiated) {
			guard springboard_services_connect_tcp(HeartbeatManager.shared.provider, &springServices) == IdeviceSuccess else {
				throw ListAppsError.err
			}
			
			var outResult: UnsafeMutableRawPointer?
			var outResultLen: Int = 0
			
			guard springboard_services_get_icon(springServices, id, &outResult, &outResultLen) == IdeviceSuccess else {
				throw ListAppsError.err
			}
			
			guard let iconPtr = outResult else {
				throw ListAppsError.err
			}
			
			springboard_services_free(springServices)
			
			let iconData = Data(bytes: iconPtr, count: outResultLen)
			return UIImage(data: iconData)
		}.value
	}
	
	static func deleteApp(for id: String) async throws {
		var installproxy: InstallationProxyClientHandle?
		
		return try await Task.detached(priority: .userInitiated) {
			guard installation_proxy_connect_tcp(HeartbeatManager.shared.provider, &installproxy) == IdeviceSuccess else {
				throw ListAppsError.err
			}
			
			guard installation_proxy_uninstall(installproxy, id, nil) == IdeviceSuccess else {
				throw ListAppsError.err
			}
		}.value
	}
}

enum ListAppsError: Error {
	case err
}

struct AppInfo: Codable, Identifiable {
	var id: String { cfBundleIdentifier ?? UUID().uuidString }
	
	let cfBundleName: String?
	let uiSupportedInterfaceOrientations: [String]?
	let dtxcodeBuild: String?
	let lsRequiresIPhoneOS: Bool?
	let uiStatusBarStyle: String?
	let entitlements: [String: AnyCodable]?
	let itsdrmScheme: AnyCodable?
	let dtPlatformVersion: String?
	let cfBundleURLTypes: [[String: AnyCodable]]?
	let dtSDKBuild: String?
	let environmentVariables: [String: String]?
	let uiSupportedDevices: [String]?
	let isAppClip: Bool?
	let cfBundleNumericVersion: Int?
	let cfBundleInfoDictionaryVersion: String?
	let sequenceNumber: Int?
	let cfBundleDisplayName: String?
	let cfBundleExecutable: String?
	let applicationType: String?
	let uiApplicationSupportsIndirectInputEvents: Bool?
	let cfBundleIconsIPad: [String: AnyCodable]?
	let isHostBackupEligible: Bool?
	let isDemotedApp: Bool?
	let dtPlatformName: String?
	let cfBundleDevelopmentRegion: String?
	let uiSupportsDocumentBrowser: Bool?
	let signerIdentity: String?
	let uiSupportedInterfaceOrientationsIPad: [String]?
	let uiRequiredDeviceCapabilities: [String]?
	let lsSupportsOpeningDocumentsInPlace: Bool?
	let dtSDKName: String?
	let dtAppStoreToolsBuild: String?
	let container: String?
	let minimumOSVersion: String?
	let isUpgradeable: Bool?
	let applicationDSID: Int?
	let uiFileSharingEnabled: Bool?
	let dtCompiler: String?
	let dtPlatformBuild: String?
	let cfBundleIdentifier: String?
	let path: String?
	let cfBundleVersion: String?
	let cfBundleShortVersionString: String?
	let cfBundleSupportedPlatforms: [String]?
	let cfBundleIcons: [String: AnyCodable]?
	let uiLaunchScreen: AnyCodable?
	let buildMachineOSBuild: String?
	let uiApplicationSceneManifest: [String: AnyCodable]?
	let cfBundlePackageType: String?
	let uiDeviceFamily: [Int]?
	let dtxcode: String?
	
	enum CodingKeys: String, CodingKey {
		case cfBundleName = "CFBundleName"
		case uiSupportedInterfaceOrientations = "UISupportedInterfaceOrientations"
		case dtxcodeBuild = "DTXcodeBuild"
		case lsRequiresIPhoneOS = "LSRequiresIPhoneOS"
		case uiStatusBarStyle = "UIStatusBarStyle"
		case entitlements = "Entitlements"
		case itsdrmScheme = "ITSAppUsesNonExemptEncryption"
		case dtPlatformVersion = "DTPlatformVersion"
		case cfBundleURLTypes = "CFBundleURLTypes"
		case dtSDKBuild = "DTSDKBuild"
		case environmentVariables = "EnvironmentVariables"
		case uiSupportedDevices = "UISupportedDevices"
		case isAppClip = "IsAppClip"
		case cfBundleNumericVersion = "CFBundleNumericVersion"
		case cfBundleInfoDictionaryVersion = "CFBundleInfoDictionaryVersion"
		case sequenceNumber = "SequenceNumber"
		case cfBundleDisplayName = "CFBundleDisplayName"
		case cfBundleExecutable = "CFBundleExecutable"
		case applicationType = "ApplicationType"
		case uiApplicationSupportsIndirectInputEvents = "UIApplicationSupportsIndirectInputEvents"
		case cfBundleIconsIPad = "CFBundleIcons~ipad"
		case isHostBackupEligible = "IsHostBackupEligible"
		case isDemotedApp = "IsDemotedApp"
		case dtPlatformName = "DTPlatformName"
		case cfBundleDevelopmentRegion = "CFBundleDevelopmentRegion"
		case uiSupportsDocumentBrowser = "UISupportsDocumentBrowser"
		case signerIdentity = "SignerIdentity"
		case uiSupportedInterfaceOrientationsIPad = "UISupportedInterfaceOrientations~ipad"
		case uiRequiredDeviceCapabilities = "UIRequiredDeviceCapabilities"
		case lsSupportsOpeningDocumentsInPlace = "LSSupportsOpeningDocumentsInPlace"
		case dtSDKName = "DTSDKName"
		case dtAppStoreToolsBuild = "DTAppStoreToolsBuild"
		case container = "Container"
		case minimumOSVersion = "MinimumOSVersion"
		case isUpgradeable = "IsUpgradeable"
		case applicationDSID = "ApplicationDSID"
		case uiFileSharingEnabled = "UIFileSharingEnabled"
		case dtCompiler = "DTCompiler"
		case dtPlatformBuild = "DTPlatformBuild"
		case cfBundleIdentifier = "CFBundleIdentifier"
		case path = "Path"
		case cfBundleVersion = "CFBundleVersion"
		case cfBundleShortVersionString = "CFBundleShortVersionString"
		case cfBundleSupportedPlatforms = "CFBundleSupportedPlatforms"
		case cfBundleIcons = "CFBundleIcons"
		case uiLaunchScreen = "UILaunchScreen"
		case buildMachineOSBuild = "BuildMachineOSBuild"
		case uiApplicationSceneManifest = "UIApplicationSceneManifest"
		case cfBundlePackageType = "CFBundlePackageType"
		case uiDeviceFamily = "UIDeviceFamily"
		case dtxcode = "DTXcode"
	}
}
