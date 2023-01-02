//
//  AppDelegate.swift
//  AvitoInternship2022
//
//  Created by Игорь Клюжев on 18.10.2022.
//

import UIKit
import EasyTipView
import Flurry_iOS_SDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else {
            return false
        }

        let initialController = UINavigationController()
        initialController.setRootWireframe(DiscoveryScreenWireframe())

        window.rootViewController = initialController
        window.makeKeyAndVisible()

        showSimulatorDataOnDesktop()
        setupTooltip()
        setupAnalytics()
        
        return true
    }

    private func showSimulatorDataOnDesktop() {
#if targetEnvironment(simulator)
        let environment = ProcessInfo.processInfo.environment
        if
            let rootFolder = environment["SIMULATOR_HOST_HOME"].map(URL.init(fileURLWithPath:))?.appendingPathComponent("Desktop/SimulatorData"),
            let simulatorHome = environment["HOME"].map(URL.init(fileURLWithPath:)),
            let simulatorVersion = environment["SIMULATOR_RUNTIME_VERSION"],
            let simulatorName = environment["SIMULATOR_DEVICE_NAME"],
            let productName = Bundle.main.infoDictionary?["CFBundleName"]
        {
            let symlink = rootFolder.appendingPathComponent("\(productName) \(simulatorName) (\(simulatorVersion))")

            let fileManager = FileManager.default
            try? fileManager.createDirectory(at: rootFolder, withIntermediateDirectories: true)
            try? fileManager.removeItem(at: symlink)
            try? fileManager.createSymbolicLink(at: symlink, withDestinationURL: simulatorHome)
        }
#endif
    }

    private func setupTooltip() {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.foregroundColor = .white
        preferences.drawing.backgroundColor = .darkGray
        preferences.drawing.arrowPosition = .top
        EasyTipView.globalPreferences = preferences

    }

    private func setupAnalytics() {
        let sb = FlurrySessionBuilder()
            .build(logLevel: FlurryLogLevel.all)
            .build(crashReportingEnabled: true)
            .build(appVersion: "1.0")
            .build(iapReportingEnabled: true)

        Flurry.startSession(apiKey: "44KW2S87X483RJ4GTB9H", sessionBuilder: sb)
    }
}
