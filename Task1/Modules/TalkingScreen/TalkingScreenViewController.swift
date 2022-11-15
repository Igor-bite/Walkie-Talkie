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

    private lazy var mapView = {
        let map = MKMapView()
        map.delegate = self
        map.showsUserLocation = true
        map.layer.cornerRadius = 10
        map.showsCompass = true
        return map
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

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setup()
    }

    private func setup() {
        view.addSubview(mapView)
        view.addSubview(talkButton)
        view.addSubview(sendOkButton)
        view.addSubview(sendLocationButton)

        mapView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.bottom.equalTo(talkButton.snp.top).offset(-20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().inset(20)
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
            make.left.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().inset(20)
            make.width.height.equalTo(60)
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        presenter.viewDidAppear()
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
}

extension TalkingScreenViewController: MKMapViewDelegate {}
