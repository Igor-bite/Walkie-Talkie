//
//  TalkingScreenWireframe.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit
import MultipeerConnectivity

final class TalkingScreenWireframe: BaseWireframe<TalkingScreenViewController> {

    init(peer: PeerModel) {
        let moduleViewController = TalkingScreenViewController()
        super.init(viewController: moduleViewController)

        let presenter = TalkingScreenPresenter(view: moduleViewController, wireframe: self, peer: peer)
        moduleViewController.presenter = presenter
    }

}

// MARK: - Extensions -

extension TalkingScreenWireframe: TalkingScreenWireframeInterface {
}
