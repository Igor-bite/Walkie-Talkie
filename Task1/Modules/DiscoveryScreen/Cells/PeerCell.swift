//
//  PeerCell.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit
import Reusable

class PeerCell: UICollectionViewCell, Reusable {
    typealias PeerCellProvider = (UICollectionView, IndexPath, PeerModel) -> PeerCell?
    static let provider: PeerCellProvider = { collectionView, indexPath, peer in
        let cell: PeerCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.configure(title: peer.name)
        return cell
    }
    private let title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        self.title.text = title
    }

    private func setup() {
        contentView.addSubview(title)
        contentView.backgroundColor = .gray.withAlphaComponent(0.2)
        contentView.layer.cornerRadius = 10

        title.textColor = .black
        title.textAlignment = .center

        title.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
