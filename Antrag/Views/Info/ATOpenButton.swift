//
//  ATOpenButton.swift
//  Antrag
//
//  Created by samara on 8.06.2025.
//

import UIKit

// MARK: - Class
class ATOpenButton: UIButton {
	
	// MARK: Overrides
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		_setup()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		_setup()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.cornerRadius = frame.height / 2
		layer.masksToBounds = true
	}
	
	// MARK: Setup
	
	private func _setup() {
		var config = UIButton.Configuration.filled()
		config.baseBackgroundColor = .systemBlue
		config.baseForegroundColor = .white
		config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
		config.cornerStyle = .capsule
		configuration = config
		
		let attributedTitle = NSAttributedString(
			string: .localized("Open"),
			attributes: [
				.font: UIFont.systemFont(ofSize: 13, weight: .bold),
				.foregroundColor: UIColor.white
			]
		)
		
		setAttributedTitle(attributedTitle, for: .normal)
	}
}
