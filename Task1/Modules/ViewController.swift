//
//  ViewController.swift
//  AvitoInternship2022
//
//  Created by Игорь Клюжев on 18.10.2022.
//

import UIKit
import SnapKit
import MultipeerConnectivity
import Reusable
import SPIndicator

class ViewController: UIViewController {
    private let conn = ConnectionManager()

    private lazy var hostButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .blue
        button.layer.cornerRadius = 10
        button.setTitle("Host", for: .normal)
        button.addTarget(self, action: #selector(host), for: .touchUpInside)
        return button
    }()

    private var isHosting = false

    private lazy var dataSource = makeDataSource()

    private lazy var peersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: UIScreen.main.bounds.width - 30, height: 50)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(cellType: PeerCell.self)
        collectionView.delegate = self
        collectionView.allowsSelection = true
        return collectionView
    }()

    typealias DataSource = UICollectionViewDiffableDataSource<Section, MCPeerID>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, MCPeerID>

    private var peers = [MCPeerID]() {
        didSet {
            applySnapshot()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setup()
        peersCollectionView.dataSource = dataSource
        conn.showAdvertisers()
        conn.addPeer = { peer in
            self.peers.append(peer)
        }

        conn.removePeer = { peer in
            self.peers.removeAll { p in
                p == peer
            }
        }

        conn.onConnectTo = { peer in
            DispatchQueue.main.async {
                let vc = TalkieViewController(conn: self.conn, peer: peer)
                self.navigationController?.pushViewController(vc, animated: true)

                self.hostButton.setTitle("Host", for: .normal)
                self.conn.stopAdvertising()
            }
        }

        conn.onDisconnectFrom = { peer in
            DispatchQueue.main.async {
                self.peersCollectionView.allowsSelection = true
                SPIndicator.present(title: "Connection declined", preset: .error)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func setup() {
        view.addSubview(hostButton)
        view.addSubview(peersCollectionView)

        hostButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(50)
            make.height.equalTo(50)
            make.width.equalTo(100)
        }

        peersCollectionView.snp.makeConstraints { make in
            make.top.equalTo(hostButton.snp.bottom).offset(15)
            make.left.right.bottom.equalToSuperview()
        }
    }

    @objc
    private func host() {
        if isHosting {
            hostButton.setTitle("Host", for: .normal)
            conn.stopAdvertising()
        } else {
            hostButton.setTitle("Unhost", for: .normal)
            conn.startAdvertising()
        }
        isHosting.toggle()
    }

    private func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: peersCollectionView,
            cellProvider: { (collectionView, indexPath, peer) ->
                UICollectionViewCell? in
                let cell: PeerCell = collectionView.dequeueReusableCell(for: indexPath)
                cell.configure(title: peer.displayName)
                return cell
            })
        return dataSource
    }

    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(peers, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let peer = peers[indexPath.row]
        conn.connectTo(peer)
        peersCollectionView.allowsSelection = false
    }
}

enum Section {
    case main
}

class PeerCell: UICollectionViewCell, Reusable {
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
        contentView.backgroundColor = .gray.withAlphaComponent(0.5)
        contentView.layer.cornerRadius = 10

        title.textColor = .black
        title.textAlignment = .center

        title.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
