//
//  TalkieViewController.swift
//  Task1
//
//  Created by Игорь Клюжев on 09.11.2022.
//

import UIKit
import SnapKit
import MultipeerConnectivity
import Reusable
import MapKit

class TalkieViewController: UIViewController {
    private let conn: ConnectionManager
    private let peer: MCPeerID

    init(conn: ConnectionManager, peer: MCPeerID) {
        self.conn = conn
        self.peer = peer
        super.init(nibName: nil, bundle: nil)

        conn.blockTalk = { title in
            DispatchQueue.main.async {
                self.talkButton.backgroundColor = .gray.withAlphaComponent(0.3)
                self.talkButton.isUserInteractionEnabled = false
                self.talkButton.setTitle(title, for: .normal)
            }
        }

        conn.unblockTalk = {
            DispatchQueue.main.async {
                self.talkButton.backgroundColor = .blue.withAlphaComponent(0.5)
                self.talkButton.isUserInteractionEnabled = true
                self.talkButton.setTitle("Talk", for: .normal)
            }
        }

        conn.addPoint = { location in
            self.addPoint(with: location)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        talkButton.backgroundColor = .blue.withAlphaComponent(0.3)
        talkButton.setTitle("Recording", for: .normal)

        conn.startStreamingVoice(to: peer)
    }

    @objc
    private func end() {
        talkButton.backgroundColor = .blue.withAlphaComponent(0.5)
        talkButton.setTitle("Talk", for: .normal)

        conn.stopStreamingVoice(to: peer)
    }

    @objc
    private func sendOk() {
        conn.sendMessage(mes: "OK", to: peer)
    }

    @objc
    private func sendLocation() {
        conn.sendLocation(to: peer)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        conn.disconnect()
    }

    func addPoint(with location: CLLocation) {
        DispatchQueue.main.async {
            let annotation = MKPointAnnotation()
            annotation.title = self.peer.displayName
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                           longitude: location.coordinate.longitude)
            self.mapView.addAnnotation(annotation)
            self.mapView.showAnnotations([annotation], animated: true)
        }
    }
}

extension TalkieViewController: MKMapViewDelegate {
    
}
