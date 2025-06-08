//
//  ListApps.swift
//  caipirinha
//
//  Created by samara on 28.05.2025.
//

import Foundation
import SwiftUICore
import UIKit

class ListApps: NSObject {
	private let _heartbeat = HeartbeatManager.shared
	
	typealias InstallationProxyClientHandle = OpaquePointer
	typealias SpringBoardServicesClientHandle = OpaquePointer
	
	var delegate: ListAppsDelegate?

	func listApps() async throws {
		var installproxy: InstallationProxyClientHandle?
		
		let allApps = try await Task.detached(priority: .userInitiated) { () -> [AppInfo] in
			guard FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile()) else {
				throw ListAppsError.err
			}
			
			guard self._heartbeat.checkSocketConnection().isConnected else {
				throw ListAppsError.err
			}
			
			guard installation_proxy_connect_tcp(self._heartbeat.provider, &installproxy) == IdeviceSuccess else {
				throw ListAppsError.err
			}
			
			var outResult: UnsafeMutableRawPointer?
			var outResultLen: Int = 0
			
			guard installation_proxy_get_apps(installproxy, nil, nil, 0, &outResult, &outResultLen) == IdeviceSuccess else {
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
							
							// JSON encode and print
							let jsonEncoder = JSONEncoder()
							jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys] // nice formatting
							
							let jsonData = try jsonEncoder.encode(appInfo)
							if let jsonString = String(data: jsonData, encoding: .utf8) {
								print(jsonString)
							}
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
			self.delegate?.updateApplications(with: allApps)
		}
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

extension ListApps {
	private static var iconCache: [String: UIImage] = [:]
	private static let iconCacheQueue = DispatchQueue(label: "iconCacheQueue")
	
	static func getAppIconCached(for id: String) async throws -> UIImage? {
		if let cached = iconCacheQueue.sync(execute: { iconCache[id] }) {
			return cached
		}
		let image = try await getAppIcon(for: id)
		if let img = image {
			iconCacheQueue.async {
				iconCache[id] = img
			}
		}
		return image
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
			
			let iconData = Data(bytes: iconPtr, count: outResultLen)
			
			springboard_services_free(springServices)
			
			return UIImage(data: iconData)
		}.value
	}
}

enum ListAppsError: Error {
	case err
}
