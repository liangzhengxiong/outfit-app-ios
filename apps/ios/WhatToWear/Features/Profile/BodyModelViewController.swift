import UIKit

class BodyModelViewController: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.title()
        label.textColor = WTWColor.textPrimary
        label.text = "选择身型录入方式"
        label.textAlignment = .center
        return label
    }()

    private lazy var templateButton = createOptionCard(
        title: "基础模板",
        subtitle: "选择预设身形",
        icon: "rectangle.grid.2x2"
    )

    private lazy var aiButton = createOptionCard(
        title: "AI体型识别",
        subtitle: "输入身高体重自动识别",
        icon: "cpu"
    )

    private lazy var manualButton = createOptionCard(
        title: "手动录入",
        subtitle: "精确输入身体数据",
        icon: "pencil"
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "身型建模"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(titleLabel)
        view.addSubview(templateButton)
        view.addSubview(aiButton)
        view.addSubview(manualButton)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(WTWLayout.verticalPadding * 2)
            make.centerX.equalToSuperview()
        }

        templateButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(WTWLayout.verticalPadding * 2)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.trailing.equalToSuperview().offset(-WTWLayout.horizontalPadding)
            make.height.equalTo(100)
        }

        aiButton.snp.makeConstraints { make in
            make.top.equalTo(templateButton.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalTo(templateButton)
            make.height.equalTo(templateButton)
        }

        manualButton.snp.makeConstraints { make in
            make.top.equalTo(aiButton.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalTo(templateButton)
            make.height.equalTo(templateButton)
        }

        templateButton.addTarget(self, action: #selector(templateTapped), for: .touchUpInside)
        aiButton.addTarget(self, action: #selector(aiTapped), for: .touchUpInside)
        manualButton.addTarget(self, action: #selector(manualTapped), for: .touchUpInside)
    }

    private func createOptionCard(title: String, subtitle: String, icon: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = WTWColor.backgroundSub
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.layer.shadowColor = WTWColor.cardShadow.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 4

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = WTWColor.primary
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.font = WTWFont.cardTitle()
        titleLabel.textColor = WTWColor.textPrimary
        titleLabel.text = title

        let subtitleLabel = UILabel()
        subtitleLabel.font = WTWFont.caption()
        subtitleLabel.textColor = WTWColor.disabled
        subtitleLabel.text = subtitle

        button.addSubview(iconView)
        button.addSubview(titleLabel)
        button.addSubview(subtitleLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(WTWLayout.cardSpacing)
            make.bottom.equalTo(button.snp.centerY).offset(-2)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(button.snp.centerY).offset(2)
        }

        return button
    }

    @objc private func templateTapped() {
        showTemplateSelection()
    }

    @objc private func aiTapped() {
        showAIInput()
    }

    @objc private func manualTapped() {
        showManualInput()
    }

    private func showTemplateSelection() {
        let vc = TemplateSelectionViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showAIInput() {
        let alert = UIAlertController(title: "AI体型识别", message: "请输入身高体重", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "身高 (cm)"
            tf.keyboardType = .numberPad
        }
        alert.addTextField { tf in
            tf.placeholder = "体重 (kg)"
            tf.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "识别", style: .default) { [weak self] _ in
            guard let heightText = alert.textFields?[0].text,
                  let weightText = alert.textFields?[1].text,
                  let height = Int(heightText),
                  let weight = Int(weightText) else { return }
            self?.submitAIBody(height: height, weight: weight)
        })
        present(alert, animated: true)
    }

    private func showManualInput() {
        let vc = ManualBodyInputViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func submitAIBody(height: Int, weight: Int) {
        Task {
            do {
                let response = try await WTWAPI.AI.classifyBody(height: height, weight: weight)
                print("Body type: \(response.bodyType), confidence: \(response.confidence)")
            } catch {
                print("Failed to classify body: \(error)")
            }
        }
    }
}

class TemplateSelectionViewController: UIViewController {
    private let models = [
        ("瘦型", "lean"),
        ("标准", "standard"),
        ("运动型", "athletic"),
        ("壮硕型", "heavy")
    ]

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 150, height: 200)
        layout.minimumInteritemSpacing = WTWLayout.cardSpacing
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(TemplateCell.self, forCellWithReuseIdentifier: "TemplateCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择模板"
        view.backgroundColor = WTWColor.secondary
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide).inset(WTWLayout.horizontalPadding) }
    }
}

extension TemplateSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TemplateCell", for: indexPath) as! TemplateCell
        cell.configure(name: models[indexPath.row].0)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = models[indexPath.row].1
        saveBodyModel(type: "template", bodyType: model)
    }

    private func saveBodyModel(type: String, bodyType: String) {
        Task {
            do {
                let _: BodyModelResponse = try await WTWAPI.User.createBodyModel(["type": type, "bodyType": bodyType])
                await MainActor.run { [weak self] in
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            } catch {
                print("Failed to save body model: \(error)")
            }
        }
    }
}

class TemplateCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = WTWColor.backgroundSub
        layer.cornerRadius = WTWLayout.cornerRadius

        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)

        imageView.backgroundColor = WTWColor.disabled.withAlphaComponent(0.3)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "person")

        nameLabel.font = WTWFont.body()
        nameLabel.textColor = WTWColor.textPrimary
        nameLabel.textAlignment = .center

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(140)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }
    }

    func configure(name: String) {
        nameLabel.text = name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ManualBodyInputViewController: UIViewController {

    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()

    private lazy var heightField = createInputField(placeholder: "身高 (cm)")
    private lazy var weightField = createInputField(placeholder: "体重 (kg)")
    private lazy var chestField = createInputField(placeholder: "胸围 (cm)")
    private lazy var waistField = createInputField(placeholder: "腰围 (cm)")
    private lazy var hipField = createInputField(placeholder: "臀围 (cm)")

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
    }

    private func setupUI() {
        title = "手动录入"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let stack = UIStackView(arrangedSubviews: [heightField, weightField, chestField, waistField, hipField, saveButton])
        stack.axis = .vertical
        stack.spacing = WTWLayout.cardSpacing

        contentView.addSubview(stack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(WTWLayout.verticalPadding)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.trailing.equalToSuperview().offset(-WTWLayout.horizontalPadding)
            make.bottom.equalToSuperview().offset(-WTWLayout.verticalPadding)
        }

        saveButton.snp.makeConstraints { make in
            make.height.equalTo(WTWLayout.buttonHeight)
        }
    }

    private func createInputField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.font = WTWFont.body()
        field.textColor = WTWColor.textPrimary
        field.backgroundColor = WTWColor.backgroundSub
        field.layer.cornerRadius = WTWLayout.cornerRadius
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        field.leftViewMode = .always
        field.keyboardType = .numberPad
        field.snp.makeConstraints { $0.height.equalTo(WTWLayout.inputHeight) }
        return field
    }

    @objc private func saveTapped() {
        let params: [String: Any] = [
            "type": "manual",
            "height": Int(heightField.text ?? "") ?? 0,
            "weight": Int(weightField.text ?? "") ?? 0,
            "chest": Int(chestField.text ?? "") ?? 0,
            "waist": Int(waistField.text ?? "") ?? 0,
            "hip": Int(hipField.text ?? "") ?? 0
        ]

        Task {
            do {
                let _: BodyModelResponse = try await WTWAPI.User.createBodyModel(params)
                await MainActor.run { [weak self] in
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            } catch {
                print("Failed to save: \(error)")
            }
        }
    }
}