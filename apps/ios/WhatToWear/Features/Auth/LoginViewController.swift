import UIKit
import SnapKit

class LoginViewController: UIViewController {

    private var countdown = 0
    private var countdownTimer: Timer?

    private lazy var phoneField: UITextField = {
        let field = UITextField()
        field.placeholder = "请输入手机号"
        field.font = WTWFont.body()
        field.textColor = WTWColor.textPrimary
        field.backgroundColor = WTWColor.backgroundSub
        field.layer.cornerRadius = WTWLayout.cornerRadius
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.keyboardType = .phonePad
        return field
    }()

    private lazy var codeField: UITextField = {
        let field = UITextField()
        field.placeholder = "请输入验证码"
        field.font = WTWFont.body()
        field.textColor = WTWColor.textPrimary
        field.backgroundColor = WTWColor.backgroundSub
        field.layer.cornerRadius = WTWLayout.cornerRadius
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.keyboardType = .numberPad
        return field
    }()

    private lazy var sendCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发送验证码", for: .normal)
        button.setTitleColor(WTWColor.primary, for: .normal)
        button.titleLabel?.font = WTWFont.caption()
        button.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("登录", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = WTWColor.primary
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()

    private lazy var wechatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "message.fill"), for: .normal)
        button.setTitle("  微信登录", for: .normal)
        button.setTitleColor(WTWColor.textPrimary, for: .normal)
        button.titleLabel?.font = WTWFont.body()
        button.backgroundColor = WTWColor.backgroundSub
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(wechatTapped), for: .touchUpInside)
        return button
    }()

    private lazy var termsLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.caption()
        label.textColor = WTWColor.disabled
        label.text = "登录即表示同意《用户协议》和《隐私政策》"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "登录"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(phoneField)
        view.addSubview(codeField)
        view.addSubview(sendCodeButton)
        view.addSubview(loginButton)
        view.addSubview(wechatButton)
        view.addSubview(termsLabel)

        phoneField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(WTWLayout.inputHeight)
        }

        codeField.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(16)
            make.leading.equalTo(phoneField)
            make.trailing.equalTo(sendCodeButton.snp.leading).offset(-12)
            make.height.equalTo(WTWLayout.inputHeight)
        }

        sendCodeButton.snp.makeConstraints { make in
            make.centerY.equalTo(codeField)
            make.trailing.equalTo(phoneField)
            make.width.equalTo(100)
        }

        loginButton.snp.makeConstraints { make in
            make.top.equalTo(codeField.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
        }

        wechatButton.snp.makeConstraints { make in
            make.top.equalTo(loginButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
        }

        termsLabel.snp.makeConstraints { make in
            make.top.equalTo(wechatButton.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
        }
    }

    @objc private func sendCodeTapped() {
        guard let phone = phoneField.text, !phone.isEmpty else {
            showAlert(title: "请输入手机号")
            return
        }

        guard /^1[3-9]\d{9}$/.test(phone) else {
            showAlert(title: "手机号格式不正确")
            return
        }

        sendCodeButton.isEnabled = false
        countdown = 60
        updateCountdown()

        AuthService.shared.sendCode(phone: phone) { [weak self] result in
            switch result {
            case .success:
                print("Code sent")
            case .failure(let error):
                self?.showAlert(title: "发送失败: \(error.localizedDescription)")
            }
        }
    }

    private func updateCountdown() {
        if countdown > 0 {
            sendCodeButton.setTitle("\(countdown)s", for: .normal)
            countdown -= 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.updateCountdown()
            }
        } else {
            sendCodeButton.setTitle("发送验证码", for: .normal)
            sendCodeButton.isEnabled = true
        }
    }

    @objc private func loginTapped() {
        guard let phone = phoneField.text, !phone.isEmpty else {
            showAlert(title: "请输入手机号")
            return
        }

        guard let code = codeField.text, !code.isEmpty else {
            showAlert(title: "请输入验证码")
            return
        }

        loginButton.isEnabled = false

        AuthService.shared.login(phone: phone, code: code) { [weak self] result in
            self?.loginButton.isEnabled = true

            switch result {
            case .success:
                self?.navigateToMain()
            case .failure(let error):
                self?.showAlert(title: "登录失败: \(error.localizedDescription)")
            }
        }
    }

    @objc private func wechatTapped() {
        #if !targetEnvironment(simulator)
        print("WeChat login would be triggered here")
        #else
        showAlert(title: "模拟器环境不支持微信登录")
        #endif
    }

    private func navigateToMain() {
        let mainVC = MainTabBarController()
        mainVC.modalPresentationStyle = .fullScreen
        present(mainVC, animated: true)
    }

    private func showAlert(title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}