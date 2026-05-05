import UIKit
import SnapKit

class MemberCenterViewController: UIViewController {

    private let memberLevels = [
        MemberLevel(title: "免费会员", subtitle: "基础功能", price: "¥0", features: ["衣物管理", "基础穿搭"], isCurrent: true),
        MemberLevel(title: "VIP会员", subtitle: "解锁全部功能", price: "¥29/月", features: ["智能搭配", "穿搭课程", "天气穿搭", "穿搭日历"], isCurrent: false),
        MemberLevel(title: "SVIP会员", subtitle: "专属服务", price: "¥99/月", features: ["全部VIP功能", "专属搭配师", "优先体验", "专属风格"], isCurrent: false)
    ]

    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.primary
        return view
    }()

    private lazy var memberIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "crown.fill"))
        iv.tintColor = WTWColor.accent
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var memberTitleLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.title()
        label.textColor = .white
        label.text = "免费会员"
        return label
    }()

    private lazy var memberSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.caption()
        label.textColor = .white.withAlphaComponent(0.8)
        label.text = "当前为免费会员，升级解锁更多功能"
        return label
    }()

    private lazy var upgradeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("立即升级", for: .normal)
        button.setTitleColor(WTWColor.primary, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = WTWColor.accent
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(upgradeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var privilegeLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.cardTitle()
        label.textColor = WTWColor.textPrimary
        label.text = "会员特权"
        return label
    }()

    private lazy var privilegeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = WTWLayout.listSpacing
        return stack
    }()

    private lazy var coursesLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.cardTitle()
        label.textColor = WTWColor.textPrimary
        label.text = "穿搭课程"
        return label
    }()

    private lazy var coursesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 160, height: 200)
        layout.minimumInteritemSpacing = WTWLayout.cardSpacing
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(CourseCell.self, forCellWithReuseIdentifier: "CourseCell")
        cv.dataSource = self
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "会员中心"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerView)
        headerView.addSubview(memberIcon)
        headerView.addSubview(memberTitleLabel)
        headerView.addSubview(memberSubtitleLabel)
        headerView.addSubview(upgradeButton)

        contentView.addSubview(privilegeLabel)
        contentView.addSubview(privilegeStack)
        contentView.addSubview(coursesLabel)
        contentView.addSubview(coursesCollectionView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(180)
        }

        memberIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(WTWLayout.verticalPadding)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.size.equalTo(40)
        }

        memberTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(memberIcon)
            make.leading.equalTo(memberIcon.snp.trailing).offset(WTWLayout.cardSpacing)
        }

        memberSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(memberTitleLabel.snp.bottom).offset(4)
            make.leading.equalTo(memberTitleLabel)
        }

        upgradeButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-WTWLayout.verticalPadding)
            make.trailing.equalToSuperview().offset(-WTWLayout.horizontalPadding)
            make.height.equalTo(36)
            make.width.equalTo(100)
        }

        privilegeLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
        }

        privilegeStack.snp.makeConstraints { make in
            make.top.equalTo(privilegeLabel.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
        }

        setupPrivilegeStack()

        coursesLabel.snp.makeConstraints { make in
            make.top.equalTo(privilegeStack.snp.bottom).offset(WTWLayout.verticalPadding * 2)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
        }

        coursesCollectionView.snp.makeConstraints { make in
            make.top.equalTo(coursesLabel.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(200)
            make.bottom.equalToSuperview().offset(-WTWLayout.verticalPadding)
        }
    }

    private func setupPrivilegeStack() {
        let privileges = [
            ("智能搭配", "sparkles", "AI智能推荐最佳穿搭"),
            ("穿搭课程", "book", "专业穿搭教程视频"),
            ("天气穿搭", "cloud.sun", "根据天气智能推荐"),
            ("穿搭日历", "calendar", "记录每日穿搭风格")
        ]

        for privilege in privileges {
            let row = createPrivilegeRow(icon: privilege.1, title: privilege.0, subtitle: privilege.2)
            privilegeStack.addArrangedSubview(row)
        }
    }

    private func createPrivilegeRow(icon: String, title: String, subtitle: String) -> UIView {
        let container = UIView()
        container.backgroundColor = WTWColor.backgroundSub
        container.layer.cornerRadius = WTWLayout.cornerRadius

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = WTWColor.primary
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.font = WTWFont.body()
        titleLabel.textColor = WTWColor.textPrimary
        titleLabel.text = title

        let subtitleLabel = UILabel()
        subtitleLabel.font = WTWFont.caption()
        subtitleLabel.textColor = WTWColor.disabled
        subtitleLabel.text = subtitle

        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-12)
        }

        return container
    }

    @objc private func upgradeTapped() {
        showUpgradeOptions()
    }

    private func showUpgradeOptions() {
        let alert = UIAlertController(title: "选择会员套餐", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "VIP会员 ¥29/月", style: .default) { [weak self] _ in
            self?.processPayment(level: "vip")
        })

        alert.addAction(UIAlertAction(title: "SVIP会员 ¥99/月", style: .default) { [weak self] _ in
            self?.processPayment(level: "svip")
        })

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        present(alert, animated: true)
    }

    private func processPayment(level: String) {
        let loadingAlert = UIAlertController(title: "正在跳转支付...", message: nil, preferredStyle: .alert)
        present(loadingAlert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            loadingAlert.dismiss(animated: true) {
                self?.showSuccessAlert()
            }
        }
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(title: "开通成功", message: "您已成为VIP会员", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.memberTitleLabel.text = "VIP会员"
            self?.memberSubtitleLabel.text = "感谢您的支持"
        })
        present(alert, animated: true)
    }
}

extension MemberCenterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseCell", for: indexPath) as! CourseCell
        cell.configure(index: indexPath.item)
        return cell
    }
}

struct MemberLevel {
    let title: String
    let subtitle: String
    let price: String
    let features: [String]
    let isCurrent: Bool
}

class CourseCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let vipBadge = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = WTWColor.backgroundSub
        layer.cornerRadius = WTWLayout.cornerRadius

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(vipBadge)

        imageView.backgroundColor = WTWColor.disabled.withAlphaComponent(0.3)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "play.rectangle")
        imageView.tintColor = WTWColor.primary

        titleLabel.font = WTWFont.body()
        titleLabel.textColor = WTWColor.textPrimary

        subtitleLabel.font = WTWFont.caption()
        subtitleLabel.textColor = WTWColor.disabled

        vipBadge.text = "VIP"
        vipBadge.font = WTWFont.caption()
        vipBadge.textColor = .white
        vipBadge.backgroundColor = WTWColor.accent
        vipBadge.layer.cornerRadius = 4
        vipBadge.clipsToBounds = true
        vipBadge.textAlignment = .center

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(100)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        vipBadge.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.width.equalTo(32)
            make.height.equalTo(18)
        }
    }

    func configure(index: Int) {
        let titles = ["韩系穿搭入门", "日系街头风", "商务休闲指南"]
        let subtitles = ["学会韩系搭配技巧", "掌握日系穿搭精髓", "商务场合穿搭建议"]

        titleLabel.text = titles[index % titles.count]
        subtitleLabel.text = subtitles[index % subtitles.count]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}