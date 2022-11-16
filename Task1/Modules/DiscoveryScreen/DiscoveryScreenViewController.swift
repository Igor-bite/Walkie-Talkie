//
//  DiscoveryScreenViewController.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit
import SnapKit

final class DiscoveryScreenViewController: UIViewController {

	// swiftlint:disable:next implicitly_unwrapped_optional
    var presenter: DiscoveryScreenPresenterInterface!

    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = UIDevice.current.name
        textField.text = UserDefaults.standard.string(forKey: ConnectionManager.peerNameKey)
        textField.addTarget(self, action: #selector(peerNameChanged), for: .editingChanged)
        return textField
    }()

    private lazy var advertiseButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .blue.withAlphaComponent(0.5)
        button.layer.cornerRadius = 10
        button.setTitle("Advertise", for: .normal)
        button.addTarget(self, action: #selector(advertiseTapped), for: .touchUpInside)
        return button
    }()

    private let dataSource: DataSource
    private let peersCollectionView: UICollectionView

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: UIScreen.main.bounds.width - 30, height: 50)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(cellType: PeerCell.self)
        collectionView.allowsSelection = true

        peersCollectionView = collectionView
        dataSource = DataSource(collectionView: collectionView, cellProvider: PeerCell.provider)

        super.init(nibName: nil, bundle: nil)

        collectionView.dataSource = dataSource
        collectionView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        title = "Discovery"
        setup()
    }

    private func setup() {
        view.addSubview(nameTextField)
        view.addSubview(advertiseButton)
        view.addSubview(peersCollectionView)

        nameTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(15)
            make.height.equalTo(50)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().inset(15)
        }

        advertiseButton.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(15)
            make.height.equalTo(50)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().inset(15)
        }

        peersCollectionView.snp.makeConstraints { make in
            make.top.equalTo(advertiseButton.snp.bottom).offset(15)
            make.left.right.bottom.equalToSuperview()
        }
    }

    @objc
    private func advertiseTapped() {
        presenter.advertiseButtonTapped()
    }

    @objc
    private func peerNameChanged() {
        if let text = nameTextField.text,
           !text.isEmpty
        {
            presenter.changePeerName(to: text)
        } else {
            presenter.changePeerName(to: UIDevice.current.name)
        }
    }
}

// MARK: - Extensions -

extension DiscoveryScreenViewController: DiscoveryScreenViewInterface {
    func applySnapshot(_ snapshot: Snapshot, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    func setAdvertiseButtonTitle(_ title: String) {
        advertiseButton.setTitle(title, for: .normal)
    }

    func setAllowsSelection(_ isAllowed: Bool) {
        peersCollectionView.allowsSelection = isAllowed
    }
}

extension DiscoveryScreenViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presenter.itemSelected(at: indexPath)
    }
}
