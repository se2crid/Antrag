//
//  AppInfo.swift
//  Antrag
//
//  Created by samara on 7.06.2025.
//

import Foundation

struct AppInfo: Codable, Identifiable {
	var id: String { CFBundleIdentifier ?? UUID().uuidString }
	
	let CFBundleName: String?
	let UISupportedInterfaceOrientations: [String]?
	let DTXcodeBuild: String?
	let LSRequiresIPhoneOS: Bool?
	let UIStatusBarStyle: String?
	let Entitlements: [String: AnyCodable]?
	let ITSAppUsesNonExemptEncryption: AnyCodable?
	let DTPlatformVersion: String?
	let CFBundleURLTypes: [[String: AnyCodable]]?
	let DTSDKBuild: String?
	let EnvironmentVariables: [String: String]?
	let UISupportedDevices: [String]?
	let IsAppClip: Bool?
	let CFBundleNumericVersion: Int?
	let CFBundleInfoDictionaryVersion: String?
	let SequenceNumber: Int?
	let CFBundleDisplayName: String?
	let CFBundleExecutable: String?
	let ApplicationType: String?
	let UIApplicationSupportsIndirectInputEvents: Bool?
	let CFBundleIcons_iPad: [String: AnyCodable]? // Note: keys with ~ipad must be adjusted
	let IsHostBackupEligible: Bool?
	let IsDemotedApp: Bool?
	let DTPlatformName: String?
	let CFBundleDevelopmentRegion: String?
	let UISupportsDocumentBrowser: Bool?
	let SignerIdentity: String?
	let UISupportedInterfaceOrientations_iPad: [String]?
	let UIRequiredDeviceCapabilities: [String]?
	let LSSupportsOpeningDocumentsInPlace: Bool?
	let DTSDKName: String?
	let DTAppStoreToolsBuild: String?
	let Container: String?
	let MinimumOSVersion: String?
	let IsUpgradeable: Bool?
	let ApplicationDSID: Int?
	let UIFileSharingEnabled: Bool?
	let DTCompiler: String?
	let DTPlatformBuild: String?
	let CFBundleIdentifier: String?
	let Path: String?
	let CFBundleVersion: String?
	let CFBundleShortVersionString: String?
	let CFBundleSupportedPlatforms: [String]?
	let CFBundleIcons: [String: AnyCodable]?
	let UILaunchScreen: AnyCodable?
	let BuildMachineOSBuild: String?
	let UIApplicationSceneManifest: [String: AnyCodable]?
	let CFBundlePackageType: String?
	let UIDeviceFamily: [Int]?
	let DTXcode: String?
}
