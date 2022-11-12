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

final class ConnectionManager: NSObject {
    private static let service = "walkie-talkie"

    let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var advertiserAssistant: MCNearbyServiceAdvertiser?
    private var nearbyServiceBrowser: MCNearbyServiceBrowser?
    private var session: MCSession?

    typealias PeerBlock = (MCPeerID) -> Void

    var addPeer: PeerBlock?
    var removePeer: PeerBlock?
    var onConnectTo: PeerBlock?
    var onDisconnectFrom: PeerBlock?

    var blockTalk: ((String) -> Void)?
    var unblockTalk: (() -> Void)?

    private let audioRecorder = AudioRecorder()
    private var player: AVAudioPlayer?

    private let audioEngine = AudioStreamer()

    override init() {
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

    func connectTo(_ peer: MCPeerID) {
        guard let session = session else { return }
        nearbyServiceBrowser?.invitePeer(peer, to: session, withContext: nil, timeout: 5)
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

    func startStreamingVoice(to peer: MCPeerID) {
        sendMessage(mes: "voice_start", to: peer)
//        audioRecorder.startRecording()
        audioEngine.startStreaming { data in
            do {
                try self.session?.send(data, toPeers: [peer], with: .reliable)
            } catch {
                DispatchQueue.main.async {
                    SPIndicator.present(title: error.localizedDescription, preset: .error)
                }
            }
        }
    }

    func stopStreamingVoice(to peer: MCPeerID) {
//        let url = audioRecorder.stopRecording()
        audioEngine.stopStreaming()
        sendMessage(mes: "voice_end", to: peer)
//        session?.sendResource(at: url, withName: "voice", toPeer: peer)
    }

    private var isGettingVoice = false
}

extension ConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let str = String(data: data, encoding: .utf8) {
            if str == "voice_start" {
                isGettingVoice = true
                return
            } else if str == "voice_end" {
                isGettingVoice = false
                return
            }
        }

        if isGettingVoice {
            print("Received voice data with size: \(data.count)")
            audioEngine.schedulePlay(data)
            return
        }

        if let str = String(data: data, encoding: .utf8) {
            if str == "Talk" {
                blockTalk?("Receiving audio")
            } else if str == "End" {

            } else {
                DispatchQueue.main.async {
                    SPIndicator.present(title: str, preset: .done)
                }
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        blockTalk?("Playing")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        guard let localURL = localURL else { return }
        print("Playing \(localURL)")
        do {
            player = try AVAudioPlayer(contentsOf: localURL)
            player?.delegate = self
            player?.play()
        } catch {
            DispatchQueue.main.async {
                SPIndicator.present(title: error.localizedDescription, preset: .error)
            }
        }
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            onDisconnectFrom?(peerID)
        case .connecting:
            break
        case .connected:
            onConnectTo?(peerID)
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
        addPeer?(peerID)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        removePeer?(peerID)
    }
}

extension ConnectionManager: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            let input = aStream as! InputStream
            var buffer = [UInt8](repeating: 0, count: 5000)
            let numberBytes = input.read(&buffer, maxLength: buffer.count)
            let dataString = NSData(bytes: &buffer, length: numberBytes)
            //            audioStreamer.scheduleBufferPlay(audioStreamer.dataToPCMBuffer(data: dataString)!)
        default:
            break
        }
    }
}

extension ConnectionManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        unblockTalk?()
    }
}
