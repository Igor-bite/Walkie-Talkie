//
//  AppDelegate.swift
//  AvitoInternship2022
//
//  Created by Игорь Клюжев on 18.10.2022.
//

import UIKit

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
}
