//
//  DiscoveryScreenWireframe.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit

final class DiscoveryScreenCoordinator: Coordinating {
  private let navigationController: UINavigationController
  private var talkingScreenCoordinator: TalkingScreenCoordinator?

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }

  func start() {
    let moduleViewController = DiscoveryScreenViewController()
    let viewModel = DiscoveryScreenViewModel(view: moduleViewController, coordinator: self)
    moduleViewController.viewModel = viewModel

    if navigationController.viewControllers.isEmpty {
      navigationController.setViewControllers([moduleViewController], animated: false)
    } else {
      navigationController.pushViewController(moduleViewController, animated: true)
    }
  }

  func finish() {
    navigationController.popViewController(animated: true)
  }
}

extension DiscoveryScreenCoordinator {
  func showTalkingScreen(withPeer peer: PeerModel) {
    let talkingScreenCoordinator = TalkingScreenCoordinator(peer: peer, navigationController: navigationController)
    self.talkingScreenCoordinator = talkingScreenCoordinator
    talkingScreenCoordinator.start()
  }

  func dismissTalkingScreen() {
    talkingScreenCoordinator?.finish()
  }
}
