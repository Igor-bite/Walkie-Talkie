//
//  DiscoveryScreenWireframe.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit

final class DiscoveryScreenWireframe: BaseWireframe<DiscoveryScreenViewController> {
    init() {
        let moduleViewController = DiscoveryScreenViewController()
        super.init(viewController: moduleViewController)

        let presenter = DiscoveryScreenPresenter(view: moduleViewController, wireframe: self)
        moduleViewController.presenter = presenter
    }

}

// MARK: - Extensions -

extension DiscoveryScreenWireframe: DiscoveryScreenWireframeInterface {
    func showTalkingScreen(withPeer peer: PeerModel) {
        navigationController?.pushWireframe(TalkingScreenWireframe(peer: peer))
    }

    func dismissTalkingScreen() {
        navigationController?.popViewController(animated: true)
    }
}
