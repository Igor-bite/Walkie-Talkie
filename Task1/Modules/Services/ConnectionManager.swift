//
//  ConnectionManager.swift
//  Task1
//
//  Created by Игорь Клюжев on 09.11.2022.
//

import Foundation
import MultipeerConnectivity
import SPIndicator
import AVFoundation
import CoreLocation

protocol ConnectionManagerDiscoveryDelegate: AnyObject {
    func peerFound(_ peer: PeerModel)
    func peerLost(_ peer: PeerModel)
    func connectedToPeer(_ peer: PeerModel)
    func disconnectedFromPeer(_ peer: PeerModel)
}

protocol ConnectionManagerSessionDelegate: AnyObject {
    func talkBlocked(withReason reason: TalkBlockReason)
    func talkUnblocked()
    func updatePeerLocation(with location: CLLocation)
}

final class ConnectionManager: NSObject {
    private enum SendFlags {
        enum Voice {
            static let start = "&voice_start"
            // voice data transmitted in between
            static let end = "&voice_end"
        }

        enum Location {
            static let flag = "&location" // &location_lat=54.3442354_lon=32.344424
        }
    }
    private static let service = "walkie-talkie"

    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var advertiserAssistant: MCNearbyServiceAdvertiser?
    private var nearbyServiceBrowser: MCNearbyServiceBrowser?
    private var session: MCSession?
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        return locationManager
    }()
    private var location: CLLocation?

    private var peerToSendLocation: MCPeerID?

    weak var discoveryDelegate: ConnectionManagerDiscoveryDelegate?
    weak var sessionDelegate: ConnectionManagerSessionDelegate?

    private let audioEngine = AudioStreamer()

    static let shared = ConnectionManager()

    private override init() {
        super.init()
        session = .init(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }

    func startAdvertising() {
        advertiserAssistant = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: ConnectionManager.service)
        advertiserAssistant?.delegate = self
        advertiserAssistant?.startAdvertisingPeer()
    }

    func stopAdvertising() {
        advertiserAssistant?.stopAdvertisingPeer()
    }

    func showAdvertisers() {
        nearbyServiceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ConnectionManager.service)
        nearbyServiceBrowser?.delegate = self
        nearbyServiceBrowser?.startBrowsingForPeers()
    }

    func connectTo(_ peer: PeerModel) {
        guard let session = session else { return }
        nearbyServiceBrowser?.invitePeer(peer.mcPeer, to: session, withContext: nil, timeout: 5)
    }

    func sendMessage(mes: String, to peer: MCPeerID) {
        do {
            try session?.send(mes.data(using: .utf8)!, toPeers: [peer], with: .reliable)
        } catch {
            DispatchQueue.main.async {
                SPIndicator.present(title: error.localizedDescription, preset: .error)
            }
        }
    }

    func disconnect() {
        session?.disconnect()
    }

    func startStreamingVoice(to peer: PeerModel) {
        sendMessage(mes: SendFlags.Voice.start, to: peer.mcPeer)
        audioEngine.startStreaming { data in
            do {
                try self.session?.send(data, toPeers: [peer.mcPeer], with: .reliable)
            } catch {
                DispatchQueue.main.async {
                    SPIndicator.present(title: error.localizedDescription, preset: .error)
                }
            }
        }
    }

    func stopStreamingVoice(to peer: MCPeerID) {
        audioEngine.stopStreaming()
        sendMessage(mes: SendFlags.Voice.end, to: peer)
    }

    func sendLocation(to peer: MCPeerID) {
        peerToSendLocation = peer
        requestLocationAccess()
        locationManager.requestLocation()
    }

    private func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }

    private var isGettingVoice = false
}

extension ConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let str = String(data: data, encoding: .utf8) {
            if str.first == "&" {
                if str == SendFlags.Voice.start {
                    isGettingVoice = true
                    sessionDelegate?.talkBlocked(withReason: .receiving)
                    return
                } else if str == SendFlags.Voice.end {
                    isGettingVoice = false
                    sessionDelegate?.talkUnblocked()
                    return
                } else {
                    let components = str.split(separator: "_")
                    if components[0] == SendFlags.Location.flag {
                        if let lat = Double(components[1].split(separator: "=")[1]),
                           let lon = Double(components[2].split(separator: "=")[1])
                        {
                            if let location = self.location {
                                let anotherLocation = CLLocation(latitude: lat, longitude: lon)

                                let distanceInMeters = location.distance(from: anotherLocation)
                                print("Distance: \(distanceInMeters)")

                                sessionDelegate?.updatePeerLocation(with: anotherLocation)
                            }
                            print("Got location: lat = \(lat), lon = \(lon)")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    SPIndicator.present(title: str, preset: .done)
                }
            }
        }

        if isGettingVoice {
            audioEngine.schedulePlay(data)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            discoveryDelegate?.disconnectedFromPeer(.init(mcPeer: peerID))
        case .connecting:
            break
        case .connected:
            discoveryDelegate?.connectedToPeer(.init(mcPeer: peerID))
        @unknown default:
            break
        }
    }
}

extension ConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard
            let window = UIApplication.shared.windows.first
        else { return }

        let title = "Invitation"
        let message = "Would you like to accept: \(peerID.displayName)"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            invitationHandler(true, self.session)
        })
        window.rootViewController?.present(alertController, animated: true)
    }
}

extension ConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        discoveryDelegate?.peerFound(.init(mcPeer: peerID))
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        discoveryDelegate?.peerLost(.init(mcPeer: peerID))
    }
}

extension ConnectionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            sendLocation(to: peerToSendLocation!)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.location = location
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude

            let encoded = "\(SendFlags.Location.flag)_lat=\(latitude)_lon=\(longitude)"
            if let data = encoded.data(using: .utf8),
               let peer = peerToSendLocation
            {
                try? session?.send(data, toPeers: [peer], with: .reliable)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        SPIndicator.present(title: error.localizedDescription, haptic: .error)
    }
}
