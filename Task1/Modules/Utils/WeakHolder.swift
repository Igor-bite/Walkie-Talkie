//
//  WeakHolder.swift
//  Task1
//
//  Created by Igor Kluzhev on 02.07.2023.
//

final class WeakHolder {
  weak var object: AnyObject?

  init(_ object: AnyObject) {
    self.object = object
  }
}
