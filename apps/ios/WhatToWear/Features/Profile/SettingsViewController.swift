import UIKit
import SnapKit

class SettingsViewController: UIViewController {

    private let settingsItems = [
        ("个人信息", "person"),
        ("清理缓存", "trash"),
        ("关于我们", "info.circle"),
        ("用户协议", "doc.text"),
        ("隐私政策", "lock.shield"),
        ("联系客服", "message")
    ]

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = WTWColor.backgroundSub
        tv.register(SettingsCell.self, forCellReuseIdentifier: "SettingsCell")
        tv.dataSource = self
        tv.delegate = self
        return tv
    }()

    private lazy var logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("退出登录", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "设置"
        view.backgroundColor = WTWColor.backgroundSub

        view.addSubview(tableView)
        view.addSubview(logoutButton)

        logoutButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-WTWLayout.verticalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
        }

        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(logoutButton.snp.top).offset(-WTWLayout.verticalPadding)
        }
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "确认退出登录？", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认", style: .destructive) { [weak self] _ in
            AuthService.shared.logout()
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
        let item = settingsItems[indexPath.row]
        cell.configure(title: item.0, icon: item.1)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0: // 个人信息
            let vc = EditProfileViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 1: // 清理缓存
            showClearCacheAlert()
        case 2: // 关于我们
            showAbout()
        default:
            break
        }
    }

    private func showClearCacheAlert() {
        let alert = UIAlertController(title: "清理缓存", message: "确定要清理缓存吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清理", style: .default) { [weak self] _ in
            self?.clearCache()
        })
        present(alert, animated: true)
    }

    private func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        let alert = UIAlertController(title: "清理完成", message: "缓存已清理", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func showAbout() {
        let alert = UIAlertController(title: "WhatToWear", message: "版本: 1.0.0\n\n一款专为男生打造的AI智能穿搭APP", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

class SettingsCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    private func setupUI() {
        accessoryType = .disclosureIndicator

        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)

        iconView.tintColor = WTWColor.primary
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = WTWFont.body()
        titleLabel.textColor = WTWColor.textPrimary

        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(12)
        }
    }

    func configure(title: String, icon: String) {
        titleLabel.text = title
        iconView.image = UIImage(systemName: icon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class EditProfileViewController: UIViewController {

    private lazy var avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.backgroundSub
        view.layer.cornerRadius = 50
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(changeAvatar))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var avatarIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.fill"))
        iv.tintColor = WTWColor.disabled
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var nicknameField = createInputField(label: "昵称", placeholder: "请输入昵称")
    private lazy var heightField = createInputField(label: "身高(cm)", placeholder: "175")
    private lazy var weightField = createInputField(label: "体重(kg)", placeholder: "70")

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = WTWColor.primary
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }

    private func setupUI() {
        title = "个人信息"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(avatarView)
        avatarView.addSubview(avatarIcon)
        view.addSubview(nicknameField)
        view.addSubview(heightField)
        view.addSubview(weightField)
        view.addSubview(saveButton)

        avatarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(WTWLayout.verticalPadding * 2)
            make.centerX.equalToSuperview()
            make.size.equalTo(100)
        }

        avatarIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(50)
        }

        nicknameField.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(WTWLayout.verticalPadding * 2)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
        }

        heightField.snp.makeConstraints { make in
            make.top.equalTo(nicknameField.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalTo(nicknameField)
        }

        weightField.snp.makeConstraints { make in
            make.top.equalTo(heightField.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalTo(nicknameField)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(weightField.snp.bottom).offset(WTWLayout.verticalPadding * 2)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
        }
    }

    private func createInputField(label: String, placeholder: String) -> UIView {
        let container = UIView()

        let labelView = UILabel()
        labelView.text = label
        labelView.font = WTWFont.caption()
        labelView.textColor = WTWColor.disabled

        let field = UITextField()
        field.placeholder = placeholder
        field.font = WTWFont.body()
        field.textColor = WTWColor.textPrimary
        field.backgroundColor = WTWColor.backgroundSub
        field.layer.cornerRadius = WTWLayout.cornerRadius
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        field.leftViewMode = .always

        container.addSubview(labelView)
        container.addSubview(field)

        labelView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        field.snp.makeConstraints { make in
            make.top.equalTo(labelView.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(WTWLayout.inputHeight)
        }

        return container
    }

    private func loadUserData() {
        Task {
            do {
                let user = try await WTWAPI.User.getMe()
                DispatchQueue.main.async { [weak self] in
                    self?.nicknameField.subviews.last?.text = user.nickname
                }
            } catch {
                print("Failed to load user: \(error)")
            }
        }
    }

    @objc private func changeAvatar() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func saveTapped() {
        let params: [String: Any] = [
            "nickname": nicknameField.subviews.last?.text ?? "",
            "height": Int(heightField.subviews.last?.text ?? "0") ?? 0,
            "weight": Int(weightField.subviews.last?.text ?? "0") ?? 0
        ]

        Task {
            do {
                let _: UserResponse = try await WTWAPI.User.updateMe(params)
                await MainActor.run { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            } catch {
                print("Failed to update profile: \(error)")
            }
        }
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            avatarIcon.image = image
            avatarIcon.contentMode = .scaleAspectFill
        }
        picker.dismiss(animated: true)
    }
}