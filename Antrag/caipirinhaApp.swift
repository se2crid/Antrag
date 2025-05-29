//
//  caipirinhaApp.swift
//  caipirinha
//
//  Created by samara on 25.05.2025.
//

import SwiftUI

@main
struct caipirinhaApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	let heartbeat = HeartbeatManager.shared
	
    var body: some Scene {
        WindowGroup {
			AppsView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		_createSourcesDirectory()
		return true
	}
	
	private func _createSourcesDirectory() {
		let fileManager = FileManager.default
		
		let directories: [URL] = [
			URL.documentsDirectory.appending(component: "keep")
		]
		
		for url in directories {
			try? fileManager.createDirectoryIfNeeded(at: url)
		}
	}
}
