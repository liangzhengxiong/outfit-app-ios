import UIKit
import SnapKit

class OutfitViewController: UIViewController {

    private var is3DMode = false

    private lazy var segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["2D平铺", "3D上身"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = WTWColor.primary
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: WTWColor.textPrimary], for: .normal)
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
    }()

    private lazy var previewView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.backgroundSub
        view.layer.cornerRadius = WTWLayout.cornerRadius
        return view
    }()

    private lazy var previewLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.body()
        label.textColor = WTWColor.disabled
        label.text = "点击智能搭配生成穿搭方案"
        label.textAlignment = .center
        return label
    }()

    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = WTWLayout.cardSpacing
        return stack
    }()

    private lazy var changeButton: UIButton = {
        let button = createActionButton(title: "换一套")
        button.addTarget(self, action: #selector(changeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = createActionButton(title: "保存穿搭")
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()

    private lazy var calendarButton: UIButton = {
        let button = createActionButton(title: "加入日历")
        button.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "穿搭搭配"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(segmentControl)
        view.addSubview(previewView)
        previewView.addSubview(previewLabel)
        view.addSubview(buttonStack)

        buttonStack.addArrangedSubview(changeButton)
        buttonStack.addArrangedSubview(saveButton)
        buttonStack.addArrangedSubview(calendarButton)

        segmentControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(WTWLayout.verticalPadding)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.trailing.equalToSuperview().offset(-WTWLayout.horizontalPadding)
            make.height.equalTo(36)
        }

        previewView.snp.makeConstraints { make in
            make.top.equalTo(segmentControl.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.trailing.equalToSuperview().offset(-WTWLayout.horizontalPadding)
            make.height.equalTo(view.snp.width).multipliedBy(1.2)
        }

        previewLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        buttonStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.trailing.equalToSuperview().offset(-WTWLayout.horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-WTWLayout.verticalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
        }
    }

    private func createActionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = WTWColor.primary
        button.layer.cornerRadius = WTWLayout.cornerRadius
        return button
    }

    @objc private func segmentChanged() {
        is3DMode = segmentControl.selectedSegmentIndex == 1
    }

    @objc private func changeTapped() {
    }

    @objc private func saveTapped() {
    }

    @objc private func calendarTapped() {
    }
}

class OutfitResultViewController: UIViewController {

    private var currentOutfit: OutfitItem?
    private var currentStyle: OutfitStyle = .korean
    private var clothes: [ClothItem] = []

    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()

    private lazy var styleSegment: UISegmentedControl = {
        let items = OutfitStyle.allCases.prefix(4).map { $0.displayName }
        let sc = UISegmentedControl(items: Array(items))
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = WTWColor.primary
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: WTWColor.textPrimary], for: .normal)
        sc.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        return sc
    }()

    private lazy var previewView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.backgroundSub
        view.layer.cornerRadius = WTWLayout.cornerRadius
        return view
    }()

    private lazy var previewStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()

    private lazy var outfitNameLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.cardTitle()
        label.textColor = WTWColor.textPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var styleLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.caption()
        label.textColor = WTWColor.disabled
        label.textAlignment = .center
        return label
    }()

    private lazy var refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        button.tintColor = WTWColor.primary
        button.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存穿搭", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = WTWColor.primary
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()

    private lazy var calendarButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("加入日历", for: .normal)
        button.setTitleColor(WTWColor.primary, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = .white
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = WTWColor.primary.cgColor
        button.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)
        return button
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = WTWColor.primary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadClothesAndGenerate()
    }

    private func setupUI() {
        title = "搭配结果"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(loadingIndicator)

        contentView.addSubview(styleSegment)
        contentView.addSubview(previewView)
        contentView.addSubview(outfitNameLabel)
        contentView.addSubview(styleLabel)
        contentView.addSubview(saveButton)
        contentView.addSubview(calendarButton)

        previewView.addSubview(previewStack)
        previewView.addSubview(refreshButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        styleSegment.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(36)
        }

        previewView.snp.makeConstraints { make in
            make.top.equalTo(styleSegment.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(200)
        }

        refreshButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(8)
            make.size.equalTo(44)
        }

        previewStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(160)
        }

        outfitNameLabel.snp.makeConstraints { make in
            make.top.equalTo(previewView.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
        }

        styleLabel.snp.makeConstraints { make in
            make.top.equalTo(outfitNameLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(styleLabel.snp.bottom).offset(WTWLayout.verticalPadding * 2)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
        }

        calendarButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
            make.bottom.equalToSuperview().offset(-WTWLayout.verticalPadding)
        }
    }

    private func loadClothesAndGenerate() {
        loadingIndicator.startAnimating()

        Task {
            do {
                let response = try await WTWAPI.Clothes.list()
                self.clothes = response.clothes
                await generateOutfit()
                loadingIndicator.stopAnimating()
            } catch {
                loadingIndicator.stopAnimating()
                showAlert(title: "加载衣物失败")
            }
        }
    }

    private func generateOutfit() async {
        do {
            let response = try await WTWAPI.Outfits.generate(
                style: currentStyle.rawValue,
                weather: nil,
                occasion: nil
            )
            await MainActor.run {
                self.currentOutfit = response.outfit
                self.updateUI()
            }
        } catch {
            await MainActor.run {
                self.showAlert(title: "生成失败")
            }
        }
    }

    private func updateUI() {
        previewStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let outfit = currentOutfit else { return }

        outfitNameLabel.text = outfit.name
        styleLabel.text = OutfitStyle(rawValue: outfit.style)?.displayName ?? outfit.style

        for cloth in outfit.clothes.prefix(3) {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = WTWColor.disabled.withAlphaComponent(0.2)
            imageView.layer.cornerRadius = 4
            imageView.clipsToBounds = true
            previewStack.addArrangedSubview(imageView)
        }
    }

    @objc private func styleChanged() {
        let styles = Array(OutfitStyle.allCases.prefix(4))
        currentStyle = styles[styleSegment.selectedSegmentIndex]
        Task { await generateOutfit() }
    }

    @objc private func refreshTapped() {
        Task { await generateOutfit() }
    }

    @objc private func saveTapped() {
        guard let outfit = currentOutfit else { return }

        let clothIds = outfit.clothes.map { $0.id }

        Task {
            do {
                let _: GenerateOutfitResponse = try await WTWAPI.Outfits.create(
                    name: outfit.name,
                    style: outfit.style,
                    clothIds: clothIds,
                    weather: outfit.weather,
                    occasion: outfit.occasion
                )

                await MainActor.run {
                    showAlert(title: "穿搭已保存")
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "保存失败")
                }
            }
        }
    }

    @objc private func calendarTapped() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        Task {
            do {
                let _: CalendarResponse = try await WTWAPI.Outfits.addToCalendar(
                    date: today,
                    outfitId: currentOutfit?.id,
                    note: nil
                )

                await MainActor.run {
                    showAlert(title: "已加入今日穿搭日历")
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "添加失败")
                }
            }
        }
    }

    private func showAlert(title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}