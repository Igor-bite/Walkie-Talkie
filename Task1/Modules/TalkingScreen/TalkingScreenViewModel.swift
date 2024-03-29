//
//  TalkingScreenViewModel.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import Foundation
import CoreLocation
import MapKit

final class TalkingScreenViewModel {
  private enum HintShowedKeys {
    static let sendOkHintHidden = "sendOkHintShowed"
    static let sendLocationHintHidden = "sendLocationHintShowed"
  }

  private weak var view: TalkingScreenViewController?
  private let coordinator: TalkingScreenCoordinator
  private let connectionManager = ConnectionManager.shared
  private let locationManager = LocationManager()
  private lazy var statEventsManager = StatEventsManager.shared

  private let peer: PeerModel
  private lazy var peerLocationAnnotation = {
    let annotation = MKPointAnnotation()
    annotation.title = self.peer.name
    return annotation
  }()
  private var shouldSendLocationOnNextUpdate = false
  private var isSharingLocation = false
  private var locationDateUpdateTimer: Timer?
  private var peerLocationUpdateDate: Date?

  init(
    view: TalkingScreenViewController,
    coordinator: TalkingScreenCoordinator,
    peer: PeerModel
  ) {
    self.view = view
    self.coordinator = coordinator
    self.peer = peer
    connectionManager.addSessionObserver(self)
    view.setPeerName(peer.name)
    locationManager.locationUpdated = { [weak self] location in
      self?.locationDidUpdate(location: location)
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
          now.timeIntervalSince(peerLocationUpdateDate) >= 1 // TODO: not working when live location
    else { return }

    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    formatter.dateTimeStyle = .numeric
    formatter.locale = .init(identifier: "en_US")
    let relative = formatter.localizedString(for: peerLocationUpdateDate, relativeTo: now)

    DispatchQueue.main.async {
      self.view?.setLocationUpdateDate(with: "Updated \(relative)")
    }
  }

  private func locationDidUpdate(location: CLLocation) {
    if shouldSendLocationOnNextUpdate {
      shouldSendLocationOnNextUpdate = false
      connectionManager.sendLocation(location, to: peer)
    }
    if isSharingLocation {
      connectionManager.sendLocation(location, to: peer)
    }
    let peerLocation = CLLocation(latitude: peerLocationAnnotation.coordinate.latitude,
                                  longitude: peerLocationAnnotation.coordinate.longitude)
    let distance = Int(peerLocation.distance(from: location))
    DispatchQueue.main.async {
      self.view?.setPeerDistance(distance)
    }
  }
}

// MARK: - Extensions -

extension TalkingScreenViewModel {
  func talkButtonTouchesBegan() {
    view?.setTalkButtonState(.blocked(reason: .recording))
    connectionManager.startStreamingVoice(to: peer)
    statEventsManager.startTimedEvent(event: .voice_streaming)
  }

  func talkButtonTouchesEnded() {
    view?.setTalkButtonState(.ready)
    connectionManager.stopStreamingVoice(to: peer)
    statEventsManager.endTimedEvent(event: .voice_streaming)
  }

  func sendOkTapped() {
    connectionManager.sendMessage(mes: "OK", to: peer)
    UserDefaults.standard.set(true, forKey: HintShowedKeys.sendOkHintHidden)
    view?.setOkButtonHintVisibility(true)
    statEventsManager.log(event: .sended_ok)
  }

  func sendLocationTapped() {
    statEventsManager.log(event: .sended_location)
    connectionManager.sendLocation(locationManager.currentLocation, to: peer)
    UserDefaults.standard.set(true, forKey: HintShowedKeys.sendLocationHintHidden)
    view?.setLocationButtonHintVisibility(true)
  }

  func toggleShareLocation() {
    UserDefaults.standard.set(true, forKey: HintShowedKeys.sendLocationHintHidden)
    view?.setLocationButtonHintVisibility(true)
    isSharingLocation.toggle()
    if isSharingLocation {
      statEventsManager.startTimedEvent(event: .location_sharing)
    } else {
      statEventsManager.endTimedEvent(event: .location_sharing)
    }
  }

  func viewWillDisappear() {
    connectionManager.disconnect()
  }

  func updateHintsVisibility() {
    view?.setOkButtonHintVisibility(UserDefaults.standard.bool(forKey: HintShowedKeys.sendOkHintHidden))
    view?.setLocationButtonHintVisibility(UserDefaults.standard.bool(forKey: HintShowedKeys.sendLocationHintHidden))
  }
}

extension TalkingScreenViewModel: ConnectionManagerSessionDelegate {
  func talkBlocked(withReason reason: TalkBlockReason) {
    DispatchQueue.main.async {
      self.view?.setTalkButtonState(.blocked(reason: reason))
    }
  }

  func talkUnblocked() {
    DispatchQueue.main.async {
      self.view?.setTalkButtonState(.ready)
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
      self.view?.showAnnotation(self.peerLocationAnnotation)
      self.view?.setPeerDistance(distance)
    }
  }
}
