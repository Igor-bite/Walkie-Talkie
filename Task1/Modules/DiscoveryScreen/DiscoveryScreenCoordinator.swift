//
//  DiscoveryScreenWireframe.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit

final class DiscoveryScreenCoordinator: Coordinating {
  private let navigationController: UINavigationController

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController

    let moduleViewController = DiscoveryScreenViewController()
    let viewModel = DiscoveryScreenViewModel(view: moduleViewController, coordinator: self)
    moduleViewController.viewModel = viewModel
  }

  func start() {}
}

extension DiscoveryScreenCoordinator {
  func showTalkingScreen(withPeer peer: PeerModel) {
    //      navigationController.pushViewController(TalkingScreenViewController(), animated: true)
  }

  func dismissTalkingScreen() {}
}
