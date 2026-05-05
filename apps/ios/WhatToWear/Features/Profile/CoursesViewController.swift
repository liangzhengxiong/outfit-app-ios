import UIKit
import SnapKit

class CoursesViewController: UIViewController {

    private let courses = [
        Course(title: "韩系穿搭入门", subtitle: "学会韩系搭配技巧", level: "免费"),
        Course(title: "日系街头风", subtitle: "掌握日系穿搭精髓", level: "VIP"),
        Course(title: "商务休闲指南", subtitle: "商务场合穿搭建议", level: "VIP"),
        Course(title: "运动风搭配", subtitle: "运动与日常的平衡", level: "免费"),
        Course(title: "复古穿搭指南", subtitle: "重温经典时尚", level: "SVIP")
    ]

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = WTWLayout.cardSpacing
        layout.minimumInteritemSpacing = WTWLayout.cardSpacing
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(CourseListCell.self, forCellWithReuseIdentifier: "CourseListCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "穿搭课程"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(WTWLayout.horizontalPadding)
        }
    }
}

extension CoursesViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return courses.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseListCell", for: indexPath) as! CourseListCell
        cell.configure(with: courses[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        return CGSize(width: width, height: 100)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let course = courses[indexPath.item]
        showCourseDetail(course)
    }

    private func showCourseDetail(_ course: Course) {
        let alert = UIAlertController(title: course.title, message: "\(course.subtitle)\n\n等级: \(course.level)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "观看", style: .default))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}

struct Course {
    let title: String
    let subtitle: String
    let level: String
}

class CourseListCell: UICollectionViewCell {
    private let thumbnailView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let levelBadge = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = WTWColor.backgroundSub
        layer.cornerRadius = WTWLayout.cornerRadius

        contentView.addSubview(thumbnailView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(levelBadge)

        thumbnailView.backgroundColor = WTWColor.disabled.withAlphaComponent(0.3)
        thumbnailView.contentMode = .scaleAspectFit
        thumbnailView.image = UIImage(systemName: "play.rectangle.fill")
        thumbnailView.tintColor = WTWColor.primary
        thumbnailView.layer.cornerRadius = 4

        titleLabel.font = WTWFont.cardTitle()
        titleLabel.textColor = WTWColor.textPrimary

        subtitleLabel.font = WTWFont.caption()
        subtitleLabel.textColor = WTWColor.disabled

        levelBadge.font = WTWFont.caption()
        levelBadge.textColor = .white
        levelBadge.backgroundColor = WTWColor.accent
        levelBadge.layer.cornerRadius = 4
        levelBadge.clipsToBounds = true
        levelBadge.textAlignment = .center

        thumbnailView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(12)
            make.width.equalTo(80)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalTo(titleLabel)
        }

        levelBadge.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-16)
            make.width.equalTo(50)
            make.height.equalTo(22)
        }
    }

    func configure(with course: Course) {
        titleLabel.text = course.title
        subtitleLabel.text = course.subtitle
        levelBadge.text = course.level

        if course.level == "SVIP" {
            levelBadge.backgroundColor = WTWColor.primary
        } else if course.level == "VIP" {
            levelBadge.backgroundColor = WTWColor.accent
        } else {
            levelBadge.backgroundColor = WTWColor.disabled
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}