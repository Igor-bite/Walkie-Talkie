//
//  TalkingScreenWireframe.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit

final class TalkingScreenCoordinator: Coordinating {
  private let navigationController: UINavigationController
  private let peer: PeerModel

  init(peer: PeerModel, navigationController: UINavigationController) {
    self.navigationController = navigationController
    self.peer = peer
  }

  func start() {
    let moduleViewController = TalkingScreenViewController()
    let viewModel = TalkingScreenViewModel(view: moduleViewController, coordinator: self, peer: peer)
    moduleViewController.viewModel = viewModel

    navigationController.pushViewController(moduleViewController, animated: true)
  }

  func finish() {
    navigationController.popViewController(animated: true)
  }
}
