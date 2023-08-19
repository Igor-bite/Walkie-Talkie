//
//  DiscoveryScreenViewController.swift
//  Task1
//
//  Created by Игорь Клюжев on 14.11.2022.
//

import UIKit
import SnapKit
import Pulsator
import UIOnboarding

final class DiscoveryScreenViewController: UIViewController {
  typealias DataSource = UICollectionViewDiffableDataSource<Section, PeerModel>
  typealias Snapshot = NSDiffableDataSourceSnapshot<Section, PeerModel>

  var viewModel: DiscoveryScreenViewModel?

  private lazy var nameTextField: UITextField = {
    let textField = UITextField()
    textField.placeholder = UIDevice.current.name
    textField.text = UserDefaults.standard.string(forKey: ConnectionManager.peerNameKey)
    textField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
    return textField
  }()

  private var name = UserDefaults.standard.string(forKey: ConnectionManager.peerNameKey) ?? UIDevice.current.name

  private lazy var saveNameButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = .inactiveColor
    button.isUserInteractionEnabled = false
    button.layer.cornerRadius = 10
    button.setTitle("Save", for: .normal)
    button.addTarget(self, action: #selector(saveNameTapped), for: .touchUpInside)
    return button
  }()

  private lazy var advertiseButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = .blue.withAlphaComponent(0.5)
    button.layer.cornerRadius = 10
    button.setTitle("Advertise", for: .normal)
    button.addTarget(self, action: #selector(advertiseTapped), for: .touchUpInside)
    return button
  }()

  private lazy var pulsator: Pulsator = {
    let pulsator = Pulsator()
    pulsator.backgroundColor = UIColor.blue.withAlphaComponent(0.7).cgColor
    pulsator.numPulse = 2
    pulsator.radius = UIScreen.main.bounds.width
    return pulsator
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

    showOnboardingIfNeeded()

    view.backgroundColor = .white
    title = "Discovery"
    setup()
    view.layer.addSublayer(pulsator)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }

  override func viewDidLayoutSubviews() {
    pulsator.position = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height + UIScreen.main.bounds.width / 3)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    pulsator.stop()
  }

  private func showOnboardingIfNeeded() {
    if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
      let onboardingController = UIOnboardingViewController(withConfiguration: .setUp())
      onboardingController.delegate = self
      navigationController?.present(onboardingController, animated: false)
    }
  }

  private func setup() {
    view.addSubview(nameTextField)
    view.addSubview(saveNameButton)
    view.addSubview(advertiseButton)
    view.addSubview(peersCollectionView)

    nameTextField.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(15)
      make.height.equalTo(40)
      make.left.equalToSuperview().offset(20)
      make.right.equalTo(saveNameButton.snp.left).inset(10)
    }

    saveNameButton.snp.makeConstraints { make in
      make.centerY.equalTo(nameTextField)
      make.height.equalTo(40)
      make.right.equalToSuperview().inset(15)
      make.width.equalTo((saveNameButton.titleLabel?.intrinsicContentSize.width ?? 0) + 40)
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
    viewModel?.advertiseButtonTapped()
    if pulsator.isPulsating {
      pulsator.stop()
    } else {
      pulsator.start()
    }
  }

  @objc
  private func saveNameTapped() {
    if let text = nameTextField.text,
       !text.isEmpty
    {
      viewModel?.changePeerName(to: text)
      name = text
    } else {
      viewModel?.changePeerName(to: UIDevice.current.name)
      name = UIDevice.current.name
    }
    saveNameButton.isUserInteractionEnabled = false
    saveNameButton.backgroundColor = .inactiveColor
    view.endEditing(true)
  }

  @objc
  private func nameChanged() {
    if nameTextField.text == "" {
      if UIDevice.current.name != name {
        saveNameButton.isUserInteractionEnabled = true
        saveNameButton.backgroundColor = .accentColor
      } else {
        saveNameButton.isUserInteractionEnabled = false
        saveNameButton.backgroundColor = .inactiveColor
      }
    } else {
      if nameTextField.text != name {
        saveNameButton.isUserInteractionEnabled = true
        saveNameButton.backgroundColor = .accentColor
      } else {
        saveNameButton.isUserInteractionEnabled = false
        saveNameButton.backgroundColor = .inactiveColor
      }
    }
  }
}

// MARK: - Extensions -

extension DiscoveryScreenViewController {
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
    viewModel?.itemSelected(at: indexPath)
  }
}

extension DiscoveryScreenViewController: UIOnboardingViewControllerDelegate {
  func didFinishOnboarding(onboardingViewController: UIOnboarding.UIOnboardingViewController) {
    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    onboardingViewController.modalTransitionStyle = .crossDissolve
    onboardingViewController.dismiss(animated: true, completion: nil)
  }
}
