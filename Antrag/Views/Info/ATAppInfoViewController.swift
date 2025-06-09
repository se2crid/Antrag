//
//  ATAppInfoViewController.swift
//  Antrag
//
//  Created by samara on 7.06.2025.
//

import UIKit
import IDeviceSwift

// MARK: - Class extension: ContentStruct
extension ATAppInfoViewController {
	struct LabeledInfo {
		let title: String
		let value: String
	}
}

// MARK: - Class
class ATAppInfoViewController: UITableViewController {
	var appIcon: UIImage? = nil
	private var _infoSections: [[LabeledInfo]] = []
	
	lazy var fadingImageView: UIImageView = {
		let size: CGFloat = 34
		
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.alpha = 0
		imageView.isHidden = true
		imageView.layer.cornerRadius = size * 0.2337
		imageView.layer.cornerCurve = .continuous
		imageView.clipsToBounds = true
		imageView.layer.borderWidth = 1.0
		imageView.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
		
		imageView.widthAnchor.constraint(equalToConstant: 34).isActive = true
		imageView.heightAnchor.constraint(equalToConstant: 34).isActive = true
		return imageView
	}()
	
	let openButton: UIButton = {
		let button = ATOpenButton(type: .system)
		button.alpha = 0
		button.isHidden = true
		return button
	}()
	
	var app: AppInfo
	
	init(app: AppInfo) {
		self.app = app
		super.init(style: .insetGrouped)
		buildInfoSections()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupNavigation()
		setupTableView()
	}
	
	// MARK: Setup
	
	func setupNavigation() {
		Task { [weak self] in
			guard let self else { return }
			if let image = try? await InstallationAppProxy.getAppIconCached(for: app.CFBundleIdentifier ?? "") {
				DispatchQueue.main.async {
					self.appIcon = image
					self.fadingImageView.image = image
					self.navigationItem.titleView = self.fadingImageView
				}
			}
		}
		
		let dismissButton = UIBarButtonItem(systemImageName: "chevron.backward.circle.fill", target: self, action: #selector(dismissAction))
		navigationItem.leftBarButtonItem = dismissButton
		
		openButton.addTarget(self, action: #selector(openButtonTapped), for: .touchUpInside)
		
		let barButtonItem = UIBarButtonItem(customView: openButton)
		navigationItem.rightBarButtonItem = barButtonItem
	}
	
	func setupTableView() {
		let header = ATAppInfoHeaderView()
		header.configure(with: app)
		
		let headerHeight: CGFloat = 120
		header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: headerHeight)
		
		tableView.tableHeaderView = header
		tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)
	}
	
	func buildInfoSections() {
		var general: [LabeledInfo] = []
		var platform: [LabeledInfo] = []
		var signed: [LabeledInfo] = []
		var extra: [LabeledInfo] = []
		var dicts: [LabeledInfo] = []
		var paths: [LabeledInfo] = []
		
		// general
		if let name = app.CFBundleName, !name.isEmpty {
			general.append(.init(title: .localized("Name"), value: name))
		}
		if let bundleId = app.CFBundleIdentifier, !bundleId.isEmpty {
			general.append(.init(title: .localized("Bundle Identifier"), value: bundleId))
		}
		if let type = app.ApplicationType, !type.isEmpty {
			general.append(.init(title: .localized("Type"), value: type))
		}
		
		// platform
		if let version = app.CFBundleShortVersionString, !version.isEmpty {
			platform.append(.init(title: .localized("Application Version"), value: version))
		}
		if let build = app.CFBundleVersion, !build.isEmpty {
			platform.append(.init(title: .localized("Application Build"), value: build))
		}
		if let sdk = app.DTPlatformVersion, !sdk.isEmpty {
			platform.append(.init(title: .localized("SDK Version Built with"), value: sdk))
		}
		if let minOS = app.MinimumOSVersion, !minOS.isEmpty {
			platform.append(.init(title: .localized("Minimum iOS Version Required"), value: minOS))
		}
		
		// signed
		if let signedby = app.SignerIdentity, !signedby.isEmpty {
			signed.append(.init(title: .localized("Signed by"), value: signedby))
		}
		if let isAppClip = app.IsAppClip {
			extra.append(.init(title: .localized("Is an App Clip"), value: isAppClip.description))
		}
		if let isFromAppStore = app.IsUpgradeable {
			extra.append(.init(title: .localized("Can be upgraded"), value: isFromAppStore.description))
		}
		
		// dicts
		if let entitlements = app.Entitlements, !entitlements.isEmpty {
			dicts.append(.init(title: .localized("Entitlements"), value: ""))
		}
		if let icons = app.CFBundleIcons, !icons.isEmpty {
			dicts.append(.init(title: .localized("Icons"), value: ""))
		}
		if let icons = app.CFBundleIcons_iPad, !icons.isEmpty {
			dicts.append(.init(title: .localized("Icons (iPad)"), value: ""))
		}
		
		// paths
		if let bundlePath = app.Path, !bundlePath.isEmpty {
			paths.append(.init(title: .localized("Bundle Path"), value: bundlePath))
		}
		if let containerPath = app.Container, !containerPath.isEmpty {
			paths.append(.init(title: .localized("Container Path"), value: containerPath))
		}
		
		[general, platform, signed, extra, dicts, paths].forEach {
			if !$0.isEmpty { _infoSections.append($0) }
		}
	}
	
	// MARK: Actions
	
	@objc private func dismissAction() {
		dismiss(animated: true)
	}
	
	@objc private func openButtonTapped() {
		UIApplication.openApp(with: app.CFBundleIdentifier ?? "")
	}
}

// MARK: - Class extension: TableView
extension ATAppInfoViewController {
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let offsetY = scrollView.contentOffset.y
		let fadeStart: CGFloat = 0
		let fadeEnd: CGFloat = 100
		
		let targetAlpha: CGFloat
		if offsetY <= fadeStart {
			targetAlpha = 0
		} else if offsetY >= fadeEnd {
			targetAlpha = 1
		} else {
			targetAlpha = (offsetY - fadeStart) / (fadeEnd - fadeStart)
		}
		
		if targetAlpha == 0 {
			if !fadingImageView.isHidden {
				self.fadingImageView.alpha = 0
				self.fadingImageView.isHidden = true
			}
			
			if !openButton.isHidden {
				self.openButton.alpha = 0
				self.openButton.isHidden = true
			}
		} else {
			if fadingImageView.isHidden {
				fadingImageView.alpha = 0
				fadingImageView.isHidden = false
			}
			
			if openButton.isHidden {
				openButton.alpha = 0
				openButton.isHidden = false
			}
			
			self.fadingImageView.alpha = targetAlpha
			self.openButton.alpha = targetAlpha
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		_infoSections.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		_infoSections[section].count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		let item = _infoSections[indexPath.section][indexPath.row]
		
		var config = UIListContentConfiguration.valueCell()
		config.text = item.title
		config.secondaryText = item.value
		config.secondaryTextProperties.color = .secondaryLabel
		cell.contentConfiguration = config
		
		let selectableTitles: [String] = [
			.localized("Entitlements"),
			.localized("Icons"),
			.localized("Icons (iPad)")
		]
		
		if selectableTitles.contains(item.title) {
			cell.selectionStyle = .default
			cell.accessoryType = .disclosureIndicator
		} else {
			cell.selectionStyle = .none
			cell.accessoryType = .none
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = _infoSections[indexPath.section][indexPath.row]
		
		if item.title == .localized("Entitlements") {
			let detailVC = ATDictionaryViewController(title: item.title, entitlements: app.Entitlements ?? [:])
			navigationController?.pushViewController(detailVC, animated: true)
		}
		
		if item.title == .localized("Icons") {
			let detailVC = ATDictionaryViewController(title: item.title, entitlements: app.CFBundleIcons ?? [:])
			navigationController?.pushViewController(detailVC, animated: true)
		}
		
		if item.title == .localized("Icons (iPad)") {
			let detailVC = ATDictionaryViewController(title: item.title, entitlements: app.CFBundleIcons_iPad ?? [:])
			navigationController?.pushViewController(detailVC, animated: true)
		}
	}
	
	override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		let item = _infoSections[indexPath.section][indexPath.row]
		
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
			let copyAction = UIAction(title: .localized("Copy"), image: UIImage(systemName: "doc.on.doc")) { _ in
				UIPasteboard.general.string = item.value
			}
			return UIMenu(children: [copyAction])
		}
	}
}
