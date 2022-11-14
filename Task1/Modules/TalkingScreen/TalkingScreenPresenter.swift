//
//  TalkingScreenPresenter.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import Foundation

final class TalkingScreenPresenter {

    private unowned let view: TalkingScreenViewInterface
    private let wireframe: TalkingScreenWireframeInterface

    init(
        view: TalkingScreenViewInterface,
        wireframe: TalkingScreenWireframeInterface
    ) {
        self.view = view
        self.wireframe = wireframe
    }
}

// MARK: - Extensions -

extension TalkingScreenPresenter: TalkingScreenPresenterInterface {
}
