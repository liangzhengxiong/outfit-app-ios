import UIKit
import SnapKit

class ProfileViewController: UIViewController {

    private let menuItems = [
        ("穿搭课程", "book"),
        ("会员中心", "crown"),
        ("穿搭日历", "calendar"),
        ("设置", "gearshape")
    ]

    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.secondary
        return view
    }()

    private lazy var avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.backgroundSub
        view.layer.cornerRadius = 40
        return view
    }()

    private lazy var avatarIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "person.fill"))
        iv.tintColor = WTWColor.disabled
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.cardTitle()
        label.textColor = WTWColor.textPrimary
        label.text = "点击登录"
        return label
    }()

    private lazy var vipBadge: UILabel = {
        let label = UILabel()
        label.font = WTWFont.caption()
        label.textColor = .white
        label.text = "VIP"
        label.backgroundColor = WTWColor.accent
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var menuTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = WTWColor.secondary
        tv.separatorStyle = .singleLine
        tv.separatorColor = WTWColor.separator
        tv.register(MenuCell.self, forCellReuseIdentifier: "MenuCell")
        tv.dataSource = self
        tv.delegate = self
        tv.isScrollEnabled = false
        return tv
    }()

    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.caption()
        label.textColor = WTWColor.disabled
        label.text = "v1.0.0"
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "我的"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(headerView)
        headerView.addSubview(avatarView)
        avatarView.addSubview(avatarIcon)
        headerView.addSubview(nicknameLabel)
        headerView.addSubview(vipBadge)
        view.addSubview(menuTableView)
        view.addSubview(versionLabel)

        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(100)
        }

        avatarView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.size.equalTo(80)
        }

        avatarIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }

        nicknameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(avatarView.snp.trailing).offset(WTWLayout.cardSpacing)
        }

        vipBadge.snp.makeConstraints { make in
            make.centerY.equalTo(nicknameLabel)
            make.leading.equalTo(nicknameLabel.snp.trailing).offset(8)
            make.width.equalTo(40)
            make.height.equalTo(20)
        }

        menuTableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(CGFloat(menuItems.count) * 56)
        }

        versionLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-WTWLayout.verticalPadding)
            make.centerX.equalToSuperview()
        }
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath) as! MenuCell
        let item = menuItems[indexPath.row]
        cell.configure(title: item.0, icon: item.1)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0: // 穿搭课程
            let vc = CoursesViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 1: // 会员中心
            let vc = MemberCenterViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 2: // 穿搭日历
            let vc = OutfitCalendarViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 3: // 设置
            let vc = SettingsViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}

class MenuCell: UITableViewCell {
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

        iconView.tintColor = WTWColor.textPrimary
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = WTWFont.body()
        titleLabel.textColor = WTWColor.textPrimary

        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(WTWLayout.cardSpacing)
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