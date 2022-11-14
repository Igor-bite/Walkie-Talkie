//
//  DiscoveryScreenPresenter.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import Foundation

final class DiscoveryScreenPresenter {

    private unowned let view: DiscoveryScreenViewInterface
    private let wireframe: DiscoveryScreenWireframeInterface
    private var peers = [PeerModel]() {
        didSet {
            applySnapshot()
        }
    }
    
    private let connectionManager = ConnectionManager.shared
    private var isAdvertising = false

    init(
        view: DiscoveryScreenViewInterface,
        wireframe: DiscoveryScreenWireframeInterface
    ) {
        self.view = view
        self.wireframe = wireframe

        connectionManager.discoveryDelegate = self
        connectionManager.showAdvertisers()
    }

    private func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(peers, toSection: Section.main)
        view.applySnapshot(snapshot, animatingDifferences: animatingDifferences)
    }
}

// MARK: - Extensions -

extension DiscoveryScreenPresenter: DiscoveryScreenPresenterInterface {
    func itemSelected(at indexPath: IndexPath) {
        let peer = peers[indexPath.row]
        connectionManager.connectTo(peer)
        self.view.setAllowsSelection(false)
    }

    func advertiseButtonTapped() {
        if isAdvertising {
            view.setAdvertiseButtonTitle("Host")
            connectionManager.stopAdvertising()
        } else {
            view.setAdvertiseButtonTitle("Unhost")
            connectionManager.startAdvertising()
        }
        isAdvertising.toggle()
    }
}

extension DiscoveryScreenPresenter: ConnectionManagerDiscoveryDelegate {
    func peerFound(_ peer: PeerModel) {
        peers.append(peer)
    }

    func peerLost(_ peer: PeerModel) {
        peers.removeAll { p in
            p == peer
        }
    }

    func connectedToPeer(_ peer: PeerModel) {
        DispatchQueue.main.async {
            self.wireframe.showTalkingScreen(withPeer: peer)
            self.view.setAdvertiseButtonTitle("Host")
        }
        self.connectionManager.stopAdvertising()
    }

    func disconnectedFromPeer(_ peer: PeerModel) {
        DispatchQueue.main.async {
            self.view.setAllowsSelection(true)
            self.wireframe.showIndicator(withTitle: "Connection declined", message: nil, preset: .error)
            self.wireframe.dismissTalkingScreen()
        }
    }
}

