import UIKit
import SnapKit

class HomeViewController: UIViewController {

    private var weather: WeatherItem?
    private var recentOutfits: [OutfitItem] = []

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private lazy var weatherView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.backgroundSub
        view.layer.cornerRadius = WTWLayout.cornerRadius
        return view
    }()

    private lazy var weatherIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32)
        return label
    }()

    private lazy var weatherTempLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.cardTitle()
        label.textColor = WTWColor.textPrimary
        label.text = "--°C"
        return label
    }()

    private lazy var weatherDescLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.caption()
        label.textColor = WTWColor.disabled
        label.text = "加载中..."
        return label
    }()

    private lazy var cameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = WTWColor.primary
        button.setTitle("拍照存衣", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        return button
    }()

    private lazy var outfitButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = WTWColor.accent
        button.setTitle("智能一键搭配", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(outfitTapped), for: .touchUpInside)
        return button
    }()

    private lazy var recentOutfitsLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.cardTitle()
        label.textColor = WTWColor.textPrimary
        label.text = "最近穿搭"
        return label
    }()

    private lazy var recentCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 160)
        layout.minimumInteritemSpacing = WTWLayout.cardSpacing
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(OutfitCardCell.self, forCellWithReuseIdentifier: "OutfitCardCell")
        cv.dataSource = self
        return cv
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.body()
        label.textColor = WTWColor.disabled
        label.text = "暂无穿搭记录"
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadWeather()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecentOutfits()
    }

    private func setupUI() {
        title = "首页"
        view.backgroundColor = WTWColor.secondary
        navigationController?.navigationBar.prefersLargeTitles = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(weatherView)
        weatherView.addSubview(weatherIconLabel)
        weatherView.addSubview(weatherTempLabel)
        weatherView.addSubview(weatherDescLabel)

        contentView.addSubview(cameraButton)
        contentView.addSubview(outfitButton)
        contentView.addSubview(recentOutfitsLabel)
        contentView.addSubview(recentCollectionView)
        contentView.addSubview(emptyLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        weatherView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(80)
        }

        weatherIconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        weatherTempLabel.snp.makeConstraints { make in
            make.leading.equalTo(weatherIconLabel.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
        }

        weatherDescLabel.snp.makeConstraints { make in
            make.leading.equalTo(weatherTempLabel)
            make.top.equalTo(weatherTempLabel.snp.bottom).offset(4)
        }

        cameraButton.snp.makeConstraints { make in
            make.top.equalTo(weatherView.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
        }

        outfitButton.snp.makeConstraints { make in
            make.top.equalTo(cameraButton.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.height.equalTo(cameraButton)
        }

        recentOutfitsLabel.snp.makeConstraints { make in
            make.top.equalTo(outfitButton.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
        }

        recentCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recentOutfitsLabel.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
            make.trailing.equalToSuperview()
            make.height.equalTo(160)
            make.bottom.equalToSuperview().offset(-WTWLayout.verticalPadding)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(recentCollectionView)
        }
    }

    private func loadWeather() {
        WeatherService.shared.requestLocationPermission()

        Task {
            do {
                let response = try await WTWAPI.AI.getWeather(lat: 39.9042, lon: 116.4074)
                await MainActor.run {
                    self.weather = response.weather
                    self.updateWeatherUI()
                }
            } catch {
                await MainActor.run {
                    self.weatherDescLabel.text = "天气加载失败"
                }
            }
        }
    }

    private func updateWeatherUI() {
        guard let weather = weather else { return }

        weatherTempLabel.text = "\(weather.temp)°C"
        weatherDescLabel.text = weather.condition

        let icon: String
        switch weather.condition.lowercased() {
        case let c where c.contains("sun") || c.contains("晴"):
            icon = "☀️"
        case let c where c.contains("cloud") || c.contains("多云"):
            icon = "☁️"
        case let c where c.contains("rain") || c.contains("雨"):
            icon = "🌧️"
        case let c where c.contains("snow"):
            icon = "❄️"
        default:
            icon = "🌤️"
        }
        weatherIconLabel.text = icon
    }

    private func loadRecentOutfits() {
        Task {
            do {
                let response = try await WTWAPI.Outfits.generate(style: nil, weather: nil, occasion: nil)
                await MainActor.run {
                    if let outfit = response.outfit, !outfit.clothes.isEmpty {
                        self.recentOutfits = [outfit]
                        self.recentCollectionView.reloadData()
                        self.emptyLabel.isHidden = true
                    } else {
                        self.emptyLabel.isHidden = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }

    @objc private func cameraTapped() {
        let addVC = AddClothingViewController()
        let navVC = UINavigationController(rootViewController: addVC)
        present(navVC, animated: true)
    }

    @objc private func outfitTapped() {
        let resultVC = OutfitResultViewController()
        navigationController?.pushViewController(resultVC, animated: true)
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recentOutfits.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutfitCardCell", for: indexPath) as! OutfitCardCell
        cell.configure(with: recentOutfits[indexPath.item])
        return cell
    }
}

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
    }
}

class OutfitCardCell: UICollectionViewCell {
    private let previewStack = UIStackView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = WTWColor.backgroundSub
        layer.cornerRadius = WTWLayout.cornerRadius
        clipsToBounds = true

        contentView.addSubview(previewStack)
        contentView.addSubview(nameLabel)

        previewStack.axis = .horizontal
        previewStack.distribution = .fillEqually
        previewStack.spacing = 2

        nameLabel.font = WTWFont.caption()
        nameLabel.textColor = WTWColor.textPrimary
        nameLabel.textAlignment = .center

        previewStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(100)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(previewStack.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(4)
        }
    }

    func configure(with outfit: OutfitItem) {
        nameLabel.text = outfit.name

        previewStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for cloth in outfit.clothes.prefix(3) {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = WTWColor.disabled.withAlphaComponent(0.2)
            if let url = URL(string: cloth.imageUrl) {
                imageView.kf.setImage(with: url)
            }
            previewStack.addArrangedSubview(imageView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}