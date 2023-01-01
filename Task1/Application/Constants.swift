//
//  Constants.swift
//  Task1
//
//  Created by Игорь Клюжев on 01.01.2023.
//

import UIKit

extension UIColor {
    static let accentColor = UIColor(red: 126/255, green: 132/255, blue: 247/255, alpha: 1)
    static let inactiveColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
}

enum Emojis {
    static let all = "🐶🐱🐭🐹🐰🐻🦊🐼🐻‍❄️🐨🐯🦁🐮🐷🐸🐵🦄🐝🐙🐳🐬🐲"

    static var random: String {
        "\(all.randomElement() ?? "🐶")"
    }
}
