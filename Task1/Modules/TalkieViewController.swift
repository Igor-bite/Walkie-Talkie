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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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


    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setup()
    }

    private func setup() {
        view.addSubview(talkButton)
        view.addSubview(sendOkButton)

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
    }

    @objc
    private func talk() {
        talkButton.backgroundColor = .blue.withAlphaComponent(0.3)
        talkButton.setTitle("Recording", for: .normal)
        print("Talk")

        conn.sendMessage(mes: "Talk", to: peer)
        conn.startStreamingVoice()
    }

    @objc
    private func end() {
        talkButton.backgroundColor = .blue.withAlphaComponent(0.5)
        talkButton.setTitle("Talk", for: .normal)
        print("End")

        conn.sendMessage(mes: "End", to: peer)
        conn.stopStreamingVoice(peer)
    }

    @objc
    private func sendOk() {
        conn.sendMessage(mes: "OK", to: peer)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        conn.disconnect()
    }
}
