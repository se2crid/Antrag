//
//  CertificatesInfoEntitlementView.swift
//  Feather
//
//  Created by samara on 27.04.2025.
//

import SwiftUI

// MARK: - View
struct AppsDetailsAnyView: View {
	var title: String
	let entitlements: [String: AnyCodable]
	
	// MARK: Body
	var body: some View {
		List {
			ForEach(entitlements.keys.sorted(), id: \.self) { key in
				if let value = entitlements[key]?.value {
					AppsDetailsAnyCellView(key: key, value: value)
				}
			}
		}
		.navigationTitle(title)
		.listStyle(.grouped)
	}
}
