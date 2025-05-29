//
//  View+copyableText.swift
//  caipirinha
//
//  Created by samara on 28.05.2025.
//

import SwiftUI

extension View {
	func copyableText(_ textToCopy: String) -> some View {
		self.contextMenu {
			Button(action: {
				UIPasteboard.general.string = textToCopy
			}) {
				Label("Copy", systemImage: "doc.on.doc")
			}
		}
	}
}
