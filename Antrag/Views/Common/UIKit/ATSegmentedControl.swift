//
//  CapsuleSegmentedControl.swift
//  Antrag
//
//  Created by samara on 7.06.2025.
//

import UIKit

class ATSegmentedControl: UISegmentedControl {
	private var _cornerRadius: CGFloat = 16.0
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.cornerRadius = _cornerRadius
		backgroundColor = .black.withAlphaComponent(0.01)
		
		guard
			selectedSegmentIndex >= 0,
			let selectedSegment = subviews[numberOfSegments] as? UIImageView
		else {
			return
		}
		
		selectedSegment.image = nil
		selectedSegment.backgroundColor = .quaternarySystemFill
		selectedSegment.layer.removeAnimation(forKey: "SelectionBounds")
		selectedSegment.layer.cornerRadius = _cornerRadius - layer.borderWidth
		selectedSegment.bounds = CGRect(origin: .zero, size: CGSize(
			width: selectedSegment.bounds.width,
			height: bounds.height - layer.borderWidth * 2
		))
	}
}
