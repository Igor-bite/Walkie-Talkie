//
//  TalkingScreenInterfaces.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit
import CoreLocation
import MapKit

protocol TalkingScreenWireframeInterface: WireframeInterface {}

protocol TalkingScreenViewInterface: ViewInterface {
    func showAnnotation(_ annotation: MKPointAnnotation)
    func setTalkButtonState(_ state: TalkButtonState)
}

protocol TalkingScreenPresenterInterface: PresenterInterface {
    func talkButtonTouchesBegan()
    func talkButtonTouchesEnded()
    func sendOkTapped()
    func sendLocationTapped()
    func viewDidAppear()
}
