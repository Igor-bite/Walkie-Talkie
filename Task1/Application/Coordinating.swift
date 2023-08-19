//
//  Coordinating.swift
//  Task1
//
//  Created by Igor Kluzhev on 01.07.2023.
//

import UIKit
import SPIndicator

protocol Coordinating: AnyObject {
  func showIndicator(withTitle title: String, message: String?, preset: SPIndicatorIconPreset)
  func start()
  func finish()
}

extension Coordinating {
  func showIndicator(withTitle title: String,
                     message: String? = nil,
                     preset: SPIndicatorIconPreset) {
    SPIndicator.present(title: title, message: message, preset: preset)
  }
}
