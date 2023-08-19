//
//  File.swift
//  Task1
//
//  Created by Igor Kluzhev on 19.08.2023.
//

import Foundation

enum StatEventType: String {
  case trying_to_connect
  case advertise_started
  case advertise_stopped
  case peer_name_changed
  case connection_session
  case voice_streaming
  case sended_ok
  case sended_location
  case location_sharing
}
