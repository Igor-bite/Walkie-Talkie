//
//  TalkingScreenPresenter.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import Foundation
import CoreLocation
import MapKit

final class TalkingScreenPresenter {

    private unowned let view: TalkingScreenViewInterface
    private let wireframe: TalkingScreenWireframeInterface
    private let connectionManager = ConnectionManager.shared
    private let peer: PeerModel
    private lazy var peerLocationAnnotation = {
        let annotation = MKPointAnnotation()
        annotation.title = self.peer.name
        return annotation
    }()

    init(
        view: TalkingScreenViewInterface,
        wireframe: TalkingScreenWireframeInterface,
        peer: PeerModel
    ) {
        self.view = view
        self.wireframe = wireframe
        self.peer = peer
        connectionManager.sessionDelegate = self
    }
}

// MARK: - Extensions -

extension TalkingScreenPresenter: TalkingScreenPresenterInterface {
    func talkButtonTouchesBegan() {
        view.setTalkButtonState(.blocked(reason: .recording))
        connectionManager.startStreamingVoice(to: peer)
    }

    func talkButtonTouchesEnded() {
        view.setTalkButtonState(.ready)
        connectionManager.stopStreamingVoice(to: peer)
    }

    func sendOkTapped() {
        connectionManager.sendMessage(mes: "OK", to: peer.mcPeer)
    }

    func sendLocationTapped() {
        connectionManager.sendLocation(to: peer.mcPeer)
    }

    func viewDidAppear() {
        connectionManager.disconnect()
    }
}

extension TalkingScreenPresenter: ConnectionManagerSessionDelegate {
    func talkBlocked(withReason reason: TalkBlockReason) {
        DispatchQueue.main.async {
            self.view.setTalkButtonState(.blocked(reason: reason))
        }
    }

    func talkUnblocked() {
        DispatchQueue.main.async {
            self.view.setTalkButtonState(.ready)
        }
    }

    func updatePeerLocation(with location: CLLocation) {
        peerLocationAnnotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                                   longitude: location.coordinate.longitude)
        DispatchQueue.main.async {
            self.view.showAnnotation(self.peerLocationAnnotation)
        }
    }
}
