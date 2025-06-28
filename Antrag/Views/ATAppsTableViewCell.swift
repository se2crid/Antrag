//
//  ATAppsCollectionViewCell.swift
//  Antrag
//
//  Created by samara on 7.06.2025.
//

import UIKit
import IDeviceSwift

// MARK: - Class
class ATAppsTableViewCell: UITableViewCell {
	let padding: CGFloat = 14
	let cornerRadius: CGFloat = 14
	
	static let reuseIdentifier = "AppsCell"
	
	let containerView: UIView = {
		let view = UIView()
		view.backgroundColor = .quaternarySystemFill
		view.layer.cornerRadius = 16
		view.layer.cornerCurve = .continuous
		view.clipsToBounds = true
		return view
	}()
	
	let nameLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 14, weight: .semibold)
		label.numberOfLines = 0
		return label
	}()
	
	let descriptionLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 12, weight: .regular)
		label.textColor = .secondaryLabel
		label.numberOfLines = 0
		return label
	}()
	
	let iconImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.contentMode = .scaleAspectFill
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.layer.cornerCurve = .continuous
		imageView.clipsToBounds = true
		imageView.layer.borderWidth = 1.0
		imageView.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
		return imageView
	}()
	
	// MARK: Overrides
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		_setup()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override var isSelected: Bool {
		didSet {
			containerView.backgroundColor = isSelected
			? .systemGray.withAlphaComponent(0.4)
			: .quaternarySystemFill
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		iconImageView.layer.cornerRadius = iconImageView.frame.height * 0.2337
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		iconImageView.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
	}
	
	// MARK: Setup
	
	private func _setup() {
		backgroundColor = .clear
		contentView.backgroundColor = .clear
		selectionStyle = .none
		clipsToBounds = false
		
		containerView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(containerView)
		
		let labelsStackView = UIStackView(arrangedSubviews: [nameLabel, descriptionLabel])
		labelsStackView.axis = .vertical
		labelsStackView.spacing = 4
		
		[iconImageView, labelsStackView].forEach {
			$0.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview($0)
		}
		
		let halfPadding = padding / 2
		let slightlyOverHalfPadding = halfPadding * 1.3
		
		NSLayoutConstraint.activate([
			containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: halfPadding),
			containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
			containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
			containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -halfPadding),
			
			iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: slightlyOverHalfPadding),
			iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: (halfPadding * 1.45)),
			iconImageView.heightAnchor.constraint(equalTo: containerView.heightAnchor, constant: -(slightlyOverHalfPadding * 2)),
			iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor),
			
			labelsStackView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
			labelsStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: slightlyOverHalfPadding),
			labelsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding)
		])
	}
	
	func configure(with app: AppInfo) {
		let name = app.CFBundleDisplayName ?? app.CFBundleExecutable
		let version = app.CFBundleShortVersionString ?? app.CFBundleVersion ?? "0"
		let identifier = app.CFBundleIdentifier ?? ""
		
		nameLabel.text = name
		descriptionLabel.text = "\(version) • \(identifier)"
		
		Task { [weak self] in
			guard let self else { return }
			if let image = try? await InstallationAppProxy.getAppIconCached(for: identifier) {
				DispatchQueue.main.async {
					self.iconImageView.image = image
				}
			}
		}
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		iconImageView.image = nil
		nameLabel.text = nil
		descriptionLabel.text = nil
	}
}
