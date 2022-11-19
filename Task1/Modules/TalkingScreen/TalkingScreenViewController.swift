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

    private lazy var sendOkButtonHint = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = .blue.withAlphaComponent(0.4)
        label.textAlignment = .right
        label.text = "Send OK"
        return label
    }()

    private lazy var sendLocationButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .gray.withAlphaComponent(0.15)
        button.layer.cornerRadius = 30
        button.setTitle("📍", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 30)
        button.addTarget(self, action: #selector(sendLocation), for: .touchDown)
        return button
    }()

    private lazy var sendLocationButtonHint = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = .blue.withAlphaComponent(0.4)
        label.textAlignment = .left
        label.text = "Send location"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        title = "Walkie-Talkie"
        setup()
        presenter.updateHintsVisibility()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        presenter.viewWillDisappear()
    }

    private func setup() {
        view.addSubview(connectedPeerLabel)
        view.addSubview(distanceToPeerLabel)
        view.addSubview(mapView)
        view.addSubview(locationUpdateDate)
        view.addSubview(talkButton)
        view.addSubview(sendOkButton)
        view.addSubview(sendOkButtonHint)
        view.addSubview(sendLocationButton)
        view.addSubview(sendLocationButtonHint)

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

        sendOkButtonHint.snp.makeConstraints { make in
            make.right.lessThanOrEqualToSuperview().inset(3)
            make.bottom.equalToSuperview().inset(3)
            make.centerX.equalTo(sendOkButton).priority(.medium)
        }

        sendLocationButton.snp.makeConstraints { make in
            make.left.greaterThanOrEqualToSuperview().offset(20)
            make.bottom.equalToSuperview().inset(20)
            make.width.height.equalTo(60)
        }

        sendLocationButtonHint.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(3)
            make.bottom.equalToSuperview().inset(3)
            make.centerX.equalTo(sendLocationButton).priority(.medium)
        }
    }

    @objc
    private func talk() {
        presenter.talkButtonTouchesBegan()
    }

    @objc
    private func end() {
        presenter.talkButtonTouchesEnded()
    }

    @objc
    private func sendOk() {
        presenter.sendOkTapped()
    }

    @objc
    private func sendLocation() {
        presenter.sendLocationTapped()
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
        mapView.showAnnotations([annotation], animated: true)
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

    func setLocationButtonHintVisibility(_ isHidden: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.5 : 0, delay: 0) {
            self.sendLocationButtonHint.alpha = isHidden ? 0 : 1
        }
    }

    func setOkButtonHintVisibility(_ isHidden: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.5 : 0, delay: 0) {
            self.sendOkButtonHint.alpha = isHidden ? 0 : 1
        }
    }
}

extension TalkingScreenViewController: MKMapViewDelegate {}
