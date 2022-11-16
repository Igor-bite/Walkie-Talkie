//
//  DiscoveryScreenInterfaces.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit

protocol DiscoveryScreenWireframeInterface: WireframeInterface {
    func showTalkingScreen(withPeer peer: PeerModel)
    func dismissTalkingScreen()
}

protocol DiscoveryScreenViewInterface: ViewInterface {
    typealias DataSource = DiscoveryScreenPresenterInterface.DataSource
    typealias Snapshot = DiscoveryScreenPresenterInterface.Snapshot

    func applySnapshot(_ snapshot: Snapshot, animatingDifferences: Bool)
    func setAdvertiseButtonTitle(_ title: String)
    func setAllowsSelection(_ isAllowed: Bool)
}

protocol DiscoveryScreenPresenterInterface: PresenterInterface {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, PeerModel>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, PeerModel>

    func itemSelected(at indexPath: IndexPath)
    func advertiseButtonTapped()
    func changePeerName(to name: String)
}
