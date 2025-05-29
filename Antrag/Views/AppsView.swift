//
//  ContentView.swift
//  caipirinha
//
//  Created by samara on 25.05.2025.
//

import SwiftUI

// MARK: - View
struct AppsView: View {
	@StateObject var viewModel = AppsViewModel()
	
	@State var selectedCategory: AppType = .user
	@State var searchText: String = ""
	@State var sortAlphabetically: Bool = true
	@State var isSettingsPresenting: Bool = false
	
	private var filteredApps: [AppInfo] {
		let apps = selectedCategory == .user ? viewModel.apps : viewModel.systemApps
		
		let searched = apps.filter { app in
			guard !searchText.isEmpty else { return true }
			return (app.cfBundleName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
			(app.cfBundleIdentifier?.localizedCaseInsensitiveContains(searchText) ?? false)
		}
		
		return searched.sorted {
			let name0 = $0.cfBundleName ?? ""
			let name1 = $1.cfBundleName ?? ""
			return sortAlphabetically ? (name0 < name1) : (name0 > name1)
		}
	}
	
	var body: some View {
		NavigationStack {
			List(filteredApps, id: \.cfBundleIdentifier) { app in
				NavigationLink {
					AppsDetailView(app: app)
				} label: {
					AppsCellView(app: app, viewModel: viewModel)
				}
			}
			.listStyle(.plain)
			.navigationTitle("Apps")
			.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
			.toolbar {
				ToolbarItem(placement: .principal) {
					Picker("Category", selection: $selectedCategory) {
						ForEach(AppType.allCases) { category in
							Text(category.rawValue).tag(category)
						}
					}
					.pickerStyle(.segmented)
					.frame(width: 150)
				}
				
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(action: {
						sortAlphabetically.toggle()
					}) {
						Image(systemName: sortAlphabetically ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
					}
					.help("Toggle Alphabetical Sort")
				}
				
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Settings", systemImage: "gearshape.circle") {
						isSettingsPresenting = true
					}
				}
				
				ToolbarItem(placement: .navigationBarLeading) {
					Button("Get") {
						get()
					}
				}
			}
			.sheet(isPresented: $isSettingsPresenting) {
				SYSettingsView()
			}
		}
	}
	
	func get() {
		Task {
			do {
				try await ListApps(viewModel: viewModel).listApps()
				try await ListApps(viewModel: viewModel).listApps(type: .system)
			} catch {
				await MainActor.run {
					UIAlertController.showAlertWithOk(
						title: "Error",
						message: error.localizedDescription,
						action: {
							HeartbeatManager.shared.start(true)
						}
					)
				}
			}
		}
	}
}
