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
    func setLocationUpdateDate(with text: String)
    func setTalkButtonState(_ state: TalkButtonState)
    func setPeerName(_ name: String)
    func setPeerDistance(_ distance: Int?)
    func setLocationButtonHintVisibility(_ isHidden: Bool)
    func setOkButtonHintVisibility(_ isHidden: Bool)
}

protocol TalkingScreenPresenterInterface: PresenterInterface {
    func talkButtonTouchesBegan()
    func talkButtonTouchesEnded()
    func sendOkTapped()
    func sendLocationTapped()
    func viewWillDisappear()
    func updateHintsVisibility()
    func toggleShareLocation()
}
