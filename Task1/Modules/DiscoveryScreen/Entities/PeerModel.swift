//
//  PeerModel.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import Foundation
import MultipeerConnectivity

struct PeerModel: Hashable {
    let mcPeer: MCPeerID

    var name: String {
        mcPeer.displayName
    }
}
