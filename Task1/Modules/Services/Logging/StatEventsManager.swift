//
//  StatEventsManager.swift
//  Task1
//
//  Created by Igor Kluzhev on 19.08.2023.
//

import Foundation
import Flurry_iOS_SDK

final class StatEventsManager {
  static let shared = StatEventsManager()

  private init() {}

  func log(event: StatEventType) {
    Flurry.log(eventName: event.rawValue)
  }

  func startTimedEvent(event: StatEventType) {
    Flurry.log(eventName: event.rawValue, timed: true)
  }

  func endTimedEvent(event: StatEventType) {
    Flurry.endTimedEvent(eventName: event.rawValue, parameters: nil)
  }
}

