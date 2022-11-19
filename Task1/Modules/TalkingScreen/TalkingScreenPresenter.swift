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
    private var shouldSendLocationOnNextUpdate = false
    private var locationDateUpdateTimer: Timer?
    private var peerLocationUpdateDate: Date?

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
        locationManager.locationUpdated = { [weak self] location in
            guard let self = self else { return }
            if self.shouldSendLocationOnNextUpdate {
                self.shouldSendLocationOnNextUpdate = false
                self.connectionManager.sendLocation(location, to: peer)
            }
            let peerLocation = CLLocation(latitude: self.peerLocationAnnotation.coordinate.latitude,
                                          longitude: self.peerLocationAnnotation.coordinate.longitude)
            let distance = Int(peerLocation.distance(from: location))
            DispatchQueue.main.async {
                self.view.setPeerDistance(distance)
            }
        }
        shouldSendLocationOnNextUpdate = true
        locationManager.startUpdatingLocation()
        createTimerForDateUpdate()
    }

    deinit {
        locationDateUpdateTimer?.invalidate()
    }

    private func createTimerForDateUpdate() {
        locationDateUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.updateLocationUpdateDate()
        }
        locationDateUpdateTimer?.tolerance = 0.1
    }

    @objc
    private func updateLocationUpdateDate() {
        let now = Date()
        guard let peerLocationUpdateDate = self.peerLocationUpdateDate,
              now.timeIntervalSince(peerLocationUpdateDate) >= 1
        else { return }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.dateTimeStyle = .numeric
        formatter.locale = .init(identifier: "en_US")
        let relative = formatter.localizedString(for: peerLocationUpdateDate, relativeTo: now)

        DispatchQueue.main.async {
            self.view.setLocationUpdateDate(with: "Updated \(relative)")
        }
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
        connectionManager.sendMessage(mes: "OK", to: peer)
        UserDefaults.standard.set(true, forKey: HintShowedKeys.sendOkHintHidden)
        view.setOkButtonHintVisibility(true, animated: true)
    }

    func sendLocationTapped() {
        connectionManager.sendLocation(locationManager.currentLocation, to: peer)
        UserDefaults.standard.set(true, forKey: HintShowedKeys.sendLocationHintHidden)
        view.setLocationButtonHintVisibility(true, animated: true)
    }

    func viewWillDisappear() {
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
        peerLocationUpdateDate = Date()
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
