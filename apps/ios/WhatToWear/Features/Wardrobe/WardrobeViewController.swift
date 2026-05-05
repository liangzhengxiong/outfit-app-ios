import UIKit
import SnapKit

class WardrobeViewController: UIViewController {

    private let categories = ["全部", "上衣", "裤装", "鞋履", "配饰"]
    private let categoryTypes: [String: String?] = [
        "全部": nil,
        "上衣": "top",
        "裤装": "bottom",
        "鞋履": "shoes",
        "配饰": "accessory"
    ]
    private var selectedCategory = 0
    private var clothes: [ClothItem] = []
    private var filteredClothes: [ClothItem] = []

    private lazy var categoryScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private lazy var categoryStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = WTWLayout.listSpacing
        return stack
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = WTWLayout.cardSpacing
        layout.minimumLineSpacing = WTWLayout.cardSpacing
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(ClothingCell.self, forCellWithReuseIdentifier: "ClothingCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private lazy var emptyView: UIView = {
        let view = UIView()
        let label = UILabel()
        label.font = WTWFont.body()
        label.textColor = WTWColor.disabled
        label.text = "暂无衣物，点击底部按钮添加"
        label.textAlignment = .center
        view.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCategories()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadClothes()
    }

    private func setupUI() {
        title = "我的衣橱"
        view.backgroundColor = WTWColor.secondary
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addClothing)
        )

        view.addSubview(categoryScrollView)
        categoryScrollView.addSubview(categoryStack)
        view.addSubview(collectionView)
        view.addSubview(emptyView)

        categoryScrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }

        categoryStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: WTWLayout.horizontalPadding, bottom: 0, right: WTWLayout.horizontalPadding))
            make.height.equalToSuperview()
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(categoryScrollView.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }
    }

    private func setupCategories() {
        for (index, category) in categories.enumerated() {
            let button = createCategoryButton(title: category, tag: index)
            categoryStack.addArrangedSubview(button)
        }
        updateCategoryButtonStates()
    }

    private func createCategoryButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = WTWFont.caption()
        button.tag = tag
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        selectedCategory = sender.tag
        updateCategoryButtonStates()
        filterClothes()
    }

    private func updateCategoryButtonStates() {
        for case let button as UIButton in categoryStack.arrangedSubviews {
            if button.tag == selectedCategory {
                button.backgroundColor = WTWColor.accent
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = WTWColor.backgroundSub
                button.setTitleColor(WTWColor.textPrimary, for: .normal)
            }
        }
    }

    private func loadClothes() {
        Task {
            do {
                let response = try await WTWAPI.Clothes.list()
                self.clothes = response.clothes
                filterClothes()
            } catch {
                print("Failed to load clothes: \(error)")
            }
        }
    }

    private func filterClothes() {
        let categoryName = categories[selectedCategory]
        let typeFilter = categoryTypes[categoryName] ?? nil

        if let type = typeFilter {
            filteredClothes = clothes.filter { $0.type == type }
        } else {
            filteredClothes = clothes
        }

        collectionView.reloadData()
        emptyView.isHidden = !filteredClothes.isEmpty
    }

    @objc private func addClothing() {
        let addVC = AddClothingViewController()
        let navVC = UINavigationController(rootViewController: addVC)
        present(navVC, animated: true)
    }
}

extension WardrobeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredClothes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClothingCell", for: indexPath) as! ClothingCell
        cell.configure(with: filteredClothes[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - WTWLayout.horizontalPadding * 2 - WTWLayout.cardSpacing * 2) / 3
        return CGSize(width: width, height: width * 1.2)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: WTWLayout.horizontalPadding, bottom: WTWLayout.verticalPadding, right: WTWLayout.horizontalPadding)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cloth = filteredClothes[indexPath.item]
        showClothDetail(cloth)
    }

    private func showClothDetail(_ cloth: ClothItem) {
        let alert = UIAlertController(title: cloth.subType, message: "尺码: \(cloth.size)", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.deleteCloth(cloth)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func deleteCloth(_ cloth: ClothItem) {
        Task {
            do {
                let _: EmptyResponse = try await AF.request(
                    "\(WTWAPI.baseURL)/api/clothes/\(cloth.id)",
                    method: .delete
                ).serializingDecodable().value
                loadClothes()
            } catch {
                print("Delete failed: \(error)")
            }
        }
    }
}

class ClothingCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let typeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = WTWColor.backgroundSub
        layer.cornerRadius = WTWLayout.cornerRadius
        clipsToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(typeLabel)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = WTWColor.disabled.withAlphaComponent(0.2)

        typeLabel.font = WTWFont.caption()
        typeLabel.textColor = WTWColor.textPrimary
        typeLabel.textAlignment = .center

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.75)
        }

        typeLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(with cloth: ClothItem) {
        typeLabel.text = cloth.subType
        if let url = URL(string: cloth.removedBgUrl ?? cloth.imageUrl) {
            imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}