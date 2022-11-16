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
    private enum HintShowedKeys {
        static let sendOkHintHidden = "sendOkHintShowed"
        static let sendLocationHintHidden = "sendLocationHintShowed"
    }

    private unowned let view: TalkingScreenViewInterface
    private let wireframe: TalkingScreenWireframeInterface
    private let connectionManager = ConnectionManager.shared
    private let locationManager = LocationManager()
    
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
        view.setPeerName(peer.name)
        locationManager.locationUpdated = { location in
            let peerLocation = CLLocation(latitude: self.peerLocationAnnotation.coordinate.latitude,
                                          longitude: self.peerLocationAnnotation.coordinate.longitude)
            let distance = Int(peerLocation.distance(from: location))
            DispatchQueue.main.async {
                self.view.setPeerDistance(distance)
            }
        }
        locationManager.startUpdatingLocation()
        connectionManager.sendLocation(locationManager.currentLocation, to: peer.mcPeer)
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
        UserDefaults.standard.set(true, forKey: HintShowedKeys.sendOkHintHidden)
        view.setOkButtonHintVisibility(true, animated: true)
    }

    func sendLocationTapped() {
        connectionManager.sendLocation(locationManager.currentLocation, to: peer.mcPeer)
        UserDefaults.standard.set(true, forKey: HintShowedKeys.sendLocationHintHidden)
        view.setLocationButtonHintVisibility(true, animated: true)
    }

    func viewDidAppear() {
        connectionManager.disconnect()
    }

    func updateHintsVisibility() {
        view.setOkButtonHintVisibility(UserDefaults.standard.bool(forKey: HintShowedKeys.sendOkHintHidden), animated: false)
        view.setLocationButtonHintVisibility(UserDefaults.standard.bool(forKey: HintShowedKeys.sendLocationHintHidden), animated: false)
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
        var distance: Int? = nil
        if let userLocation = locationManager.currentLocation {
            distance = Int(location.distance(from: userLocation))
        }

        DispatchQueue.main.async {
            self.view.showAnnotation(self.peerLocationAnnotation)
            self.view.setPeerDistance(distance)
        }
    }
}
