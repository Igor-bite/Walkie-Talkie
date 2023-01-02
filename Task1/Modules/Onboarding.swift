//
//  Onboarding.swift
//  Task1
//
//  Created by Игорь Клюжев on 02.01.2023.
//

import UIKit
import UIOnboarding

struct UIOnboardingHelper {
    // App Icon
    static func setUpIcon() -> UIImage {
        return UIImage(named: "walkie-talkie")!
    }

    // First Title Line
    // Welcome Text
    static func setUpFirstTitleLine() -> NSMutableAttributedString {
        .init(string: "Welcome to", attributes: [.foregroundColor: UIColor.label])
    }

    // Second Title Line
    // App Name
    static func setUpSecondTitleLine() -> NSMutableAttributedString {
        .init(string: Bundle.main.displayName ?? "Insignia", attributes: [
            .foregroundColor: UIColor.accentColor //UIColor.init(named: "camou")!
        ])
    }

    // Core Features
    static func setUpFeatures() -> Array<UIOnboardingFeature> {
        return .init([
            .init(icon: UIImage(systemName: "wifi.slash")!,
                  title: "Works without internet",
                  description: "App do not use internet at all."),
            .init(icon: UIImage(systemName: "lock.shield")!,
                  title: "Encrypted data",
                  description: "Your data is fully encrypted for communication."),
            .init(icon: UIImage(systemName: "speedometer")!,
                  title: "Easy to use",
                  description: "Quick and responsive app.")
        ])
    }

    // Notice Text
    static func setUpNotice() -> UIOnboardingTextViewConfiguration {
        return .init(icon: UIImage(systemName: "heart.fill")!.withTintColor(.accentColor),
                     text: "Developed and designed by Igor Klyuzhev.",
                     linkTitle: "Contact me...",
                     link: "",
                     tint: .accentColor)
    }

    // Continuation Title
    static func setUpButton() -> UIOnboardingButtonConfiguration {
        return .init(title: "Continue",
                     backgroundColor: .accentColor)
    }
}

extension UIOnboardingViewConfiguration {
    // UIOnboardingViewController init
    static func setUp() -> UIOnboardingViewConfiguration {
        return .init(appIcon: UIOnboardingHelper.setUpIcon(),
                     firstTitleLine: UIOnboardingHelper.setUpFirstTitleLine(),
                     secondTitleLine: UIOnboardingHelper.setUpSecondTitleLine(),
                     features: UIOnboardingHelper.setUpFeatures(),
                     textViewConfiguration: UIOnboardingHelper.setUpNotice(),
                     buttonConfiguration: UIOnboardingHelper.setUpButton())
    }
}
