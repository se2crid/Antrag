//
//  SceneDelegate.swift
//  Antrag
//
//  Created by samara on 14.05.2025.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var currentScene: UIScene?
	var window: UIWindow?

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		self.currentScene = scene
		guard let windowScene = scene as? UIWindowScene else { return }
		
		let window = UIWindow(windowScene: windowScene)
		
		// Use SwiftUI for the main interface
		let contentView = ATAppsView()
		let hostingController = UIHostingController(rootView: contentView)
		
		window.rootViewController = hostingController
		window.makeKeyAndVisible()
		self.window = window
	}
}

