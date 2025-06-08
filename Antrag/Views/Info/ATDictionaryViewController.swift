//
//  ATDictionaryViewController.swift
//  Feather
//
//  Created by samara on 27.04.2025.
//

import UIKit
import IDeviceSwift

// MARK: - Class extension: ContentStruct
extension ATDictionaryViewController {
	struct Entry: Hashable {
		let id = UUID()
		let key: String
		let value: Any
		
		func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}
		
		static func == (lhs: Entry, rhs: Entry) -> Bool {
			return lhs.id == rhs.id
		}
	}
}

// MARK: - Class
class ATDictionaryViewController: UICollectionViewController {
	typealias Section = Int
	var dataSource: UICollectionViewDiffableDataSource<Section, Entry>!
	var rootEntries: [Entry] = []
	var childrenMap: [UUID: [Entry]] = [:]
	
	let titleText: String
	let entitlements: [(String, Any)]
	
	init(title: String, entitlements: [String: AnyCodable]) {
		self.titleText = title
		self.entitlements = entitlements.sorted(by: { $0.key < $1.key }).map { ($0.key, $0.value.value) }
		super.init(collectionViewLayout: .insetGroupedSidebar())
		self.title = title
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupCollectionView()
		setupDataSource()
		configureDataSource()
	}
	
	// MARK: Setup
	
	func setupCollectionView() {
		collectionView.allowsSelection = false
		collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "cell")
	}
	
	func setupDataSource() {
		dataSource = UICollectionViewDiffableDataSource<Section, Entry>(collectionView: collectionView) {
			(collectionView, indexPath, entry) -> UICollectionViewCell? in
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! UICollectionViewListCell
			
			var config = cell.defaultContentConfiguration()
			if let _ = self.childrenMap[entry.id] {
				config.text = entry.key
				config.secondaryText = nil
			} else {
				config.text = entry.key
				config.secondaryText = self._formatted(entry.value)
				config.secondaryTextProperties.color = .secondaryLabel
			}
			
			cell.contentConfiguration = config
			
			if self.childrenMap[entry.id] != nil {
				cell.accessories = [.outlineDisclosure()]
			} else {
				cell.accessories = []
			}
			
			return cell
		}
		
		var snapshot = NSDiffableDataSourceSnapshot<Section, Entry>()
		snapshot.appendSections([0])
		dataSource.apply(snapshot, animatingDifferences: false)
	}
	
	func configureDataSource() {
		rootEntries.removeAll()
		childrenMap.removeAll()
		
		for (key, value) in entitlements {
			let root = Entry(key: key, value: value)
			rootEntries.append(root)
		}
		// Recursively build children map for all entries
		buildChildrenMap(for: rootEntries)
		
		var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Entry>()
		sectionSnapshot.append(rootEntries)
		for root in rootEntries {
			if let children = childrenMap[root.id] {
				sectionSnapshot.append(children, to: root)
				// Also append grandchildren recursively
				appendChildrenRecursively(children, to: &sectionSnapshot)
			}
		}
		
		dataSource.apply(sectionSnapshot, to: 0, animatingDifferences: false)
	}
	
	func children(for value: Any) -> [Entry]? {
		if let dict = value as? [String: Any] {
			return dict.map { (key, value) in Entry(key: key, value: value) }
		} else if let array = value as? [Any] {
			return array.enumerated().map { (index, value) in Entry(key: "\(index)", value: value) }
		} else {
			return nil
		}
	}
	
	func buildChildrenMap(for entries: [Entry]) {
		for entry in entries {
			if let children = children(for: entry.value) {
				childrenMap[entry.id] = children
				// Recursively build children for those children
				buildChildrenMap(for: children)
			}
		}
	}
	
	func appendChildrenRecursively(_ entries: [Entry], to snapshot: inout NSDiffableDataSourceSectionSnapshot<Entry>) {
		for entry in entries {
			if let children = childrenMap[entry.id] {
				snapshot.append(children, to: entry)
				appendChildrenRecursively(children, to: &snapshot)
			}
		}
	}

	
	private func _formatted(_ value: Any) -> String {
		switch value {
		case let bool as Bool:
			return bool ? "✓" : "✗"
		case let number as NSNumber:
			return number.stringValue
		case let string as String:
			return string
		default:
			return String(describing: value)
		}
	}
}

// MARK: - Class extension: CollectionView
extension ATDictionaryViewController {
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let entry = dataSource.itemIdentifier(for: indexPath) else { return nil }
		
		return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
			let copyAction = UIAction(title: .localized("Copy"), image: UIImage(systemName: "doc.on.doc")) { _ in
				let textToCopy: String
				if let children = self.childrenMap[entry.id], !children.isEmpty {
					textToCopy = entry.key
				} else {
					textToCopy = self._formatted(entry.value)
				}
				UIPasteboard.general.string = textToCopy
			}
			return UIMenu(children: [copyAction])
		}
	}
}
