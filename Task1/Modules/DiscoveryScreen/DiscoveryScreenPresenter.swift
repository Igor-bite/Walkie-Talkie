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
        connectionManager.startBrowsingForPeers()
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
        DispatchQueue.main.async {
            self.view.setAllowsSelection(false)
        }
    }

    func advertiseButtonTapped() {
        if isAdvertising {
            view.setAdvertiseButtonTitle("Advertise")
            connectionManager.stopAdvertising()
        } else {
            view.setAdvertiseButtonTitle("Stop advertising")
            connectionManager.startAdvertising()
        }
        isAdvertising.toggle()
    }

    func changePeerName(to name: String) {
        connectionManager.changePeerName(to: name)
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
            self.view.setAdvertiseButtonTitle("Advertise")
        }
        connectionManager.stopAdvertising()
    }

    func disconnectedFromPeer(_ peer: PeerModel) {
        DispatchQueue.main.async {
            self.view.setAllowsSelection(true)
            self.wireframe.showIndicator(withTitle: "Connection declined", message: nil, preset: .error)
            self.wireframe.dismissTalkingScreen()
        }
    }
}

