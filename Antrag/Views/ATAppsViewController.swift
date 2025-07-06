//
//  ATViewController.swift
//  Antrag
//
//  Created by samara on 7.06.2025.
//

import UIKit
import class SwiftUI.UIHostingController
import IDeviceSwift

// MARK: Class extension: Enum
extension ATAppsViewController {
	enum AppType: String, CaseIterable, Identifiable {
		case system = "System"
		case user = "User"
		
		var id: String {
			rawValue
		}
		
		var stringValue: String {
			.localized(rawValue)
		}
	}
}

// MARK: - Class
class ATAppsViewController: UITableViewController {
	var apps: [AppInfo] = []
	var allSortedApps: [AppInfo] = [] // backup
	var sortedApps: [AppInfo] = [] // main
	var appType: AppType = .user
	
	var appsManager: InstallationAppProxy {
		let listApps = InstallationAppProxy()
		listApps.delegate = self
		return listApps
	}
	
	private var _didLoad = false
	var selectBarButton: UIBarButtonItem!
	var deleteBarButton: UIBarButtonItem!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupTableView()
		setupNavigation()
		setupSearchController()
		setupListeners()
		setupToolbar()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setToolbarHidden(true, animated: false)
	}
	
	// MARK: Setup
	
	func setupNavigation() {
		let segmentedControl = ATSegmentedControl(items: [AppType.system.stringValue, AppType.user.stringValue])
		segmentedControl.selectedSegmentIndex = 1
		segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
		navigationItem.titleView = segmentedControl
		
		let reloadButton = UIBarButtonItem(systemImageName: "arrow.clockwise.circle.fill", target: self, action: #selector(reloadAction))
		navigationItem.leftBarButtonItem = reloadButton
		
		let settingsButton = UIBarButtonItem(systemImageName: "gear.circle.fill", target: self, action: #selector(settingsAction))
		let selectButton = UIBarButtonItem(title: .localized("Select"), style: .plain, target: self, action: #selector(selectAction))
		selectBarButton = selectButton
		navigationItem.rightBarButtonItems = [settingsButton, selectButton]
	}
	
	func setupSearchController() {
		let searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		navigationItem.searchController = searchController
		definesPresentationContext = true
	}
	
	func setupTableView() {
		tableView.separatorStyle = .none
		tableView.register(
			ATAppsTableViewCell.self,
			forCellReuseIdentifier: ATAppsTableViewCell.reuseIdentifier
		)
		tableView.allowsMultipleSelectionDuringEditing = true
	}
	
	func setupListeners() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(listApplicationsAction),
			name: .heartbeat,
			object: nil
		)
	}
	
	func setupToolbar() {
		deleteBarButton = UIBarButtonItem(title: .localized("Delete"), style: .plain, target: self, action: #selector(massDeleteAction))
		deleteBarButton.isEnabled = false
		let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		toolbarItems = [flex, deleteBarButton]
	}
	
	// MARK: Actions
	
	@objc func segmentChanged(_ sender: UISegmentedControl) {
		appType = sender.selectedSegmentIndex == 0 ? .system : .user
		filterAndReload()
	}
	
	@objc func settingsAction() {
		let nav = UIHostingController(rootView: ATSettingsView())
		nav.modalPresentationStyle = .pageSheet
		
		if let sheet = nav.sheetPresentationController {
			sheet.prefersGrabberVisible = true
		}
		
		present(nav, animated: true)
	}
	
	@objc func reloadAction() {
		_didLoad = false
		HeartbeatManager.shared.start(true)
	}
	
	@objc func listApplicationsAction() {
		guard !_didLoad else { return }
		_didLoad = true

		Task {
			do {
				try await appsManager.listApps()
			} catch {
				await MainActor.run {
					UIAlertController.showAlertWithOk(
						title: nil,
						message: error.localizedDescription,
						action: {
							HeartbeatManager.shared.start(true)
						}
					)
				}
			}
		}
	}
	
	@objc func selectAction() {
		let isEditing = tableView.isEditing
		tableView.setEditing(!isEditing, animated: true)
		navigationController?.setToolbarHidden(isEditing, animated: true)
		deleteBarButton.isEnabled = false
		deleteBarButton.title = .localized("Delete")
		updateSelectButtonTitle()
	}
	
	func updateSelectButtonTitle() {
		let title = tableView.isEditing ? .localized("Done") : .localized("Select")
		selectBarButton.title = title
	}
	
	func updateDeleteButtonState() {
		let count = tableView.indexPathsForSelectedRows?.count ?? 0
		deleteBarButton.isEnabled = count > 0
		let title: String
		if count == 0 {
			title = .localized("Delete")
		} else {
			title = .localized("Delete (%d)", arguments: count)
		}
		deleteBarButton.title = title
	}
	
	@objc func massDeleteAction() {
		guard let selected = tableView.indexPathsForSelectedRows else { return }
		let ids = selected.compactMap { sortedApps[$0.row].CFBundleIdentifier }
		guard ids.count > 0 else { return }

		let alert = UIAlertController(title: nil, message: .localized("Are you sure you want to delete %d apps?", arguments: ids.count), preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: .localized("Cancel"), style: .cancel))
		alert.addAction(UIAlertAction(title: .localized("Delete"), style: .destructive) { _ in
			Task {
				for id in ids {
					try? await InstallationAppProxy.deleteApp(for: id)
				}
				await MainActor.run {
					// remove from data sources
					self.apps.removeAll { ids.contains($0.CFBundleIdentifier ?? "") }
					self.sortedApps.removeAll { ids.contains($0.CFBundleIdentifier ?? "") }
					self.tableView.deleteRows(at: selected, with: .automatic)
					self.selectAction() // exit selection mode
				}
			}
		})
		present(alert, animated: true)
	}
}

// MARK: - Class extension: TableView
extension ATAppsViewController {
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		80
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		sortedApps.count
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.clipsToBounds = false
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: ATAppsTableViewCell.reuseIdentifier,
			for: indexPath
		) as? ATAppsTableViewCell else {
			return UITableViewCell()
		}
		
		let app = sortedApps[indexPath.row]
		cell.configure(with: app)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if tableView.isEditing {
			updateDeleteButtonState()
			return
		}
		
		let app = sortedApps[indexPath.row]
		
		tableView.deselectRow(at: indexPath, animated: true)
		
		let detailNavigationController = UINavigationController(rootViewController: ATAppInfoViewController(app: app))
		if #available(iOS 18.0, *) {
			detailNavigationController.preferredTransition = .zoom(sourceViewProvider: { context in
				guard let cell = self.tableView.cellForRow(at: indexPath) else { return nil }
				return cell
			})
		}
		
		present(detailNavigationController, animated: true)
	}
	
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		if tableView.isEditing {
			updateDeleteButtonState()
		}
	}
	
	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}
	
	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let app = sortedApps[indexPath.row]
		var actions: [UIContextualAction] = []
		
		if let id = app.CFBundleIdentifier {
			let deleteAction = UIContextualAction(style: .destructive, title: .localized("Delete")) { _,_,_ in
				Task {
					do {
						try await InstallationAppProxy.deleteApp(for: id)
						await MainActor.run {
							self.sortedApps.remove(at: indexPath.row)
							
							if let fullIndex = self.apps.firstIndex(where: { $0.CFBundleIdentifier == id }) {
								self.apps.remove(at: fullIndex)
							}
							
							self.tableView.deleteRows(at: [indexPath], with: .automatic)
						}
					} catch {
						await MainActor.run {
							UIAlertController.showAlertWithOk(
								title: nil,
								message: error.localizedDescription
							)
						}
					}
				}
			}

			deleteAction.image = UIImage(systemName: "trash.fill")
			deleteAction.backgroundColor = .systemRed
			actions.append(deleteAction)
			
			let openAction = UIContextualAction(style: .normal, title: .localized("Open")) { _,_,_ in
				UIApplication.openApp(with: id)
			}
			openAction.image = UIImage(systemName: "arrow.up.forward")
			actions.append(openAction)
		}
		
		let configuration = UISwipeActionsConfiguration(actions: actions)
		configuration.performsFirstActionWithFullSwipe = false
		
		return configuration
	}
	
	@available(iOS 17.0, *)
	override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
		var config: UIContentUnavailableConfiguration?
		if sortedApps.count == 0 {
			var empty = UIContentUnavailableConfiguration.empty()
			empty.background.backgroundColor = .systemBackground
			empty.image = UIImage(systemName: "nosign.app")
			empty.text = .localized("No Apps Found")
			empty.secondaryText = .localized("Please make sure you are connected to the VPN and have a pairing file.")
			empty.background = .listSidebarCell()
			
			config = empty
			contentUnavailableConfiguration = config
			return
		} else {
			contentUnavailableConfiguration = nil
			return
		}
	}
}

extension ATAppsViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		guard let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty else {
			sortedApps = allSortedApps
			tableView.reloadData()
			return
		}
		
		sortedApps = allSortedApps.filter { app in
			app.CFBundleDisplayName?.lowercased().contains(searchText) == true ||
			app.CFBundleExecutable?.lowercased().contains(searchText) == true ||
			app.CFBundleIdentifier?.lowercased().contains(searchText) == true
		}
		tableView.reloadData()
	}
}

