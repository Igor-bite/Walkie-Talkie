//
//  DiscoveryScreenViewModel.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import Foundation
import GradientLoadingBar
import Flurry_iOS_SDK
import AlertKit

final class DiscoveryScreenViewModel {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, PeerModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, PeerModel>

    private let view: DiscoveryScreenViewController
    private let coordinator: DiscoveryScreenCoordinator
    private var peers = [PeerModel]() {
        didSet {
            applySnapshot()
        }
    }
    
    private let connectionManager = ConnectionManager.shared
    private var isAdvertising = false
    private let gradientLoadingBar = GradientLoadingBar()

    init(
        view: DiscoveryScreenViewController,
        coordinator: DiscoveryScreenCoordinator
    ) {
        self.view = view
        self.coordinator = coordinator

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

extension DiscoveryScreenViewModel {
    func itemSelected(at indexPath: IndexPath) {
        Flurry.log(eventName: "trying_to_connect")
        let peer = peers[indexPath.row]
        gradientLoadingBar.fadeIn()
        connectionManager.connectTo(peer)
        DispatchQueue.main.async {
            self.view.setAllowsSelection(false)
        }
    }

    func advertiseButtonTapped() {
        if isAdvertising {
            view.setAdvertiseButtonTitle("Advertise")
            connectionManager.stopAdvertising()
            Flurry.log(eventName: "advertise_started")
        } else {
            view.setAdvertiseButtonTitle("Stop advertising")
            connectionManager.startAdvertising()
            Flurry.log(eventName: "advertise_stopped")
        }
        isAdvertising.toggle()
    }

    func changePeerName(to name: String) {
        connectionManager.changePeerName(to: name)
        Flurry.log(eventName: "peer_name_changed")
    }
}

extension DiscoveryScreenViewModel: ConnectionManagerDiscoveryDelegate {
    func peerFound(_ peer: PeerModel) {
        peers.append(peer)
    }

    func peerLost(_ peer: PeerModel) {
        peers.removeAll { p in
            p == peer
        }
    }

    func connectedToPeer(_ peer: PeerModel) {
        Flurry.log(eventName: "connection_session", timed: true)
        DispatchQueue.main.async {
            self.gradientLoadingBar.fadeOut()
            self.coordinator.showTalkingScreen(withPeer: peer)
            self.view.setAdvertiseButtonTitle("Advertise")
        }
        isAdvertising = false
        connectionManager.stopAdvertising()
    }

    func disconnectedFromPeer(_ peer: PeerModel) {
        Flurry.endTimedEvent(eventName: "connection_session", parameters: nil)
        DispatchQueue.main.async {
            self.view.setAllowsSelection(true)
            self.coordinator.showIndicator(withTitle: "Connection declined", message: nil, preset: .error)
            self.coordinator.dismissTalkingScreen()
        }
    }
}

