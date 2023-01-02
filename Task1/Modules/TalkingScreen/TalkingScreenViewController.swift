//
//  TalkingScreenViewController.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit
import SnapKit
import Reusable
import MapKit
import Pulsator
import EasyTipView

final class TalkingScreenViewController: UIViewController {
	// swiftlint:disable:next implicitly_unwrapped_optional
    var presenter: TalkingScreenPresenterInterface!

    private lazy var connectedPeerLabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()

    private lazy var distanceToPeerLabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .gray.withAlphaComponent(0.4)
        label.textAlignment = .right
        return label
    }()

    private lazy var mapView = {
        let map = MKMapView()
        map.delegate = self
        map.showsUserLocation = true
        map.layer.cornerRadius = 10
        map.showsCompass = true
        return map
    }()

    private lazy var locationUpdateDate = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .gray.withAlphaComponent(0.4)
        label.textAlignment = .center
        return label
    }()

    private lazy var talkButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .blue.withAlphaComponent(0.5)
        button.layer.cornerRadius = Double(UIScreen.main.bounds.width - 100) / 2.0
        button.setTitle("Talk", for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .boldSystemFont(ofSize: 50)
        button.addTarget(self, action: #selector(talk), for: .touchDown)
        button.addTarget(self, action: #selector(end), for: .touchUpInside)
        button.addTarget(self, action: #selector(end), for: .touchUpOutside)
        return button
    }()

    private lazy var sendOkButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .gray.withAlphaComponent(0.15)
        button.layer.cornerRadius = 30
        button.setTitle("👌", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 30)
        button.addTarget(self, action: #selector(sendOk), for: .touchDown)
        return button
    }()

    private var holdStart = Date(timeIntervalSince1970: 0)
    private var shouldRecognizeHold = true
    private let holdDuration = 0.5

    private lazy var sendLocationButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .inactiveColor
        button.layer.cornerRadius = 30
        button.setTitle("📍", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 30)
        button.addTarget(self, action: #selector(startRecognizer), for: .touchDown)
        button.addTarget(self, action: #selector(endRecognizer), for: .touchUpInside)
        let holdGR = UILongPressGestureRecognizer(target: self, action: #selector(holdRecognizer))
        button.addGestureRecognizer(holdGR)
        return button
    }()

    private lazy var pulsator: Pulsator = {
        let pulsator = Pulsator()
        pulsator.backgroundColor = UIColor.blue.withAlphaComponent(0.7).cgColor
        pulsator.numPulse = 2
        pulsator.radius = 60
        return pulsator
    }()

    private lazy var sendLocationButtonTooltip = EasyTipView(text: "TAP - send location\nHOLD - share live location")
    private lazy var sendOkButtonTooltip = EasyTipView(text: "TAP - send OK")

    private let generator = UISelectionFeedbackGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        title = "Walkie-Talkie"
        setup()
        sendLocationButton.layer.superlayer?.insertSublayer(pulsator, below: sendLocationButton.layer)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        presenter.viewWillDisappear()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    override func viewDidLayoutSubviews() {
        pulsator.position = sendLocationButton.layer.position
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.updateHintsVisibility()
        mapView.showAnnotations(mapView.annotations, animated: true)
    }

    private func setup() {
        view.addSubview(connectedPeerLabel)
        view.addSubview(distanceToPeerLabel)
        view.addSubview(mapView)
        view.addSubview(locationUpdateDate)
        view.addSubview(talkButton)
        view.addSubview(sendOkButton)
        view.addSubview(sendLocationButton)

        connectedPeerLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.lessThanOrEqualTo(distanceToPeerLabel.snp.left).inset(10)
        }

        distanceToPeerLabel.snp.makeConstraints { make in
            make.bottom.equalTo(connectedPeerLabel)
            make.right.equalToSuperview().inset(20)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(connectedPeerLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().inset(20)
            make.bottom.equalTo(locationUpdateDate.snp.top).offset(-5)
        }

        locationUpdateDate.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().inset(10)
            make.bottom.equalTo(talkButton.snp.top).offset(-15)
        }

        talkButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().inset(50)
            make.height.equalTo(talkButton.snp.width)
            make.bottom.equalToSuperview().inset(100)
        }

        sendOkButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
            make.width.height.equalTo(60)
        }

        sendLocationButton.snp.makeConstraints { make in
            make.left.greaterThanOrEqualToSuperview().offset(20)
            make.bottom.equalToSuperview().inset(20)
            make.width.height.equalTo(60)
        }
    }

    @objc
    private func talk() {
        generator.prepare()
        generator.selectionChanged()
        presenter.talkButtonTouchesBegan()
    }

    @objc
    private func end() {
        generator.prepare()
        generator.selectionChanged()
        presenter.talkButtonTouchesEnded()
    }

    @objc
    private func sendOk() {
        generator.prepare()
        generator.selectionChanged()
        presenter.sendOkTapped()
    }

    @objc
    private func holdRecognizer(sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            stopScale()
            holdStart = Date(timeIntervalSince1970: 0)
            return
        }

        guard shouldRecognizeHold else { return }

        if holdStart == Date(timeIntervalSince1970: 0) {
            holdStart = Date()
            startScale()
        } else {
            if Date().timeIntervalSince1970 - holdStart.timeIntervalSince1970 > holdDuration {
                shouldRecognizeHold = false
                toggleShareLocation()
                stopScale()
                holdStart = Date(timeIntervalSince1970: 0)
            }
        }
    }

    private func startScale() {
        UIView.animate(withDuration: holdDuration) {
            self.sendLocationButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
    }

    private func stopScale() {
        UIView.animate(withDuration: 0.1) {
            self.sendLocationButton.transform = .identity
        }
    }

    @objc
    private func startRecognizer() {
        shouldRecognizeHold = true

        if holdStart == Date(timeIntervalSince1970: 0) {
            holdStart = Date()
            startScale()
        }

        print(#function)
    }

    @objc
    private func endRecognizer() {
        stopScale()
        holdStart = Date(timeIntervalSince1970: 0)
        sendLocation()
    }

    private func sendLocation() {
        generator.prepare()
        generator.selectionChanged()
        presenter.sendLocationTapped()
    }

    private func toggleShareLocation() {
        generator.prepare()
        generator.selectionChanged()
        presenter.toggleShareLocation()
        if pulsator.isPulsating {
            pulsator.stop()
            sendLocationButton.backgroundColor = .inactiveColor
        } else {
            pulsator.start()
            sendLocationButton.backgroundColor = .accentColor
        }
    }
}

enum TalkButtonState {
    case ready
    case blocked(reason: TalkBlockReason)
}

// MARK: - Extensions -

extension TalkingScreenViewController: TalkingScreenViewInterface {
    func showAnnotation(_ annotation: MKPointAnnotation) {
        if mapView.view(for: annotation) == nil {
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }

    func setLocationUpdateDate(with text: String) {
        UIView.animate(withDuration: 0.3, delay: 0) {
            self.locationUpdateDate.text = text
        }
    }

    func setTalkButtonState(_ state: TalkButtonState) {
        switch state {
        case .ready:
            talkButton.backgroundColor = .blue.withAlphaComponent(0.5)
            talkButton.isUserInteractionEnabled = true
            talkButton.setTitle("Talk", for: .normal)
        case .blocked(let reason):
            talkButton.backgroundColor = .gray.withAlphaComponent(0.3)
            talkButton.isUserInteractionEnabled = reason == .recording
            talkButton.setTitle(reason.rawValue, for: .normal)
        }
    }

    func setPeerName(_ name: String) {
        connectedPeerLabel.text = name
    }

    func setPeerDistance(_ distance: Int?) {
        UIView.animate(withDuration: 0.5, delay: 0) {
            if let distance = distance {
                self.distanceToPeerLabel.alpha = 1
                self.distanceToPeerLabel.text = "~\(distance) m"
            } else {
                self.distanceToPeerLabel.alpha = 0
                self.distanceToPeerLabel.text = nil
            }
        }
    }

    func setLocationButtonHintVisibility(_ isHidden: Bool) {
        if !isHidden {
            sendLocationButtonTooltip.show(forView: sendLocationButton)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.sendLocationButtonTooltip.dismiss()
            }
        } else {
            sendLocationButtonTooltip.dismiss()
        }
    }

    func setOkButtonHintVisibility(_ isHidden: Bool) {
        if !isHidden {
            sendOkButtonTooltip.show(forView: sendOkButton)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.sendOkButtonTooltip.dismiss()
            }
        } else {
            sendOkButtonTooltip.dismiss()
        }
    }
}

extension TalkingScreenViewController: MKMapViewDelegate {}
