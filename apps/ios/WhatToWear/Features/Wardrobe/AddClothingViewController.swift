import UIKit
import SnapKit

class ImageUploadService {

    static let shared = ImageUploadService()

    private init() {}

    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "ImageUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
                }
                return
            }

            let base64 = imageData.base64EncodedString()
            let mockUrl = "https://storage.example.com/images/\(UUID().uuidString).jpg"

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion(.success(mockUrl))
            }
        }
    }

    func processClothingImage(_ image: UIImage, completion: @escaping (Result<ProcessedImage, Error>) -> Void) {
        uploadImage(image) { result in
            switch result {
            case .success(let imageUrl):
                Task {
                    do {
                        let response = try await WTWAPI.AI.removeBackground(imageUrl: imageUrl)
                        let processed = ProcessedImage(
                            originalUrl: imageUrl,
                            processedUrl: response.resultUrl,
                            segments: response.segments
                        )
                        DispatchQueue.main.async {
                            completion(.success(processed))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

struct ProcessedImage {
    let originalUrl: String
    let processedUrl: String
    let segments: [String]
}

class AddClothingViewController: UIViewController {

    private var selectedImage: UIImage?
    private var selectedType: String = "top"
    private var selectedSubType: String = "tshirt"
    private var selectedSize: String = "M"
    private var selectedFit: String = "standard"

    private let types = ["top", "bottom", "shoes", "accessory"]
    private let subTypes: [String: [String]] = [
        "top": ["tshirt", "shirt", "polo", "sweater", "jacket", "coat"],
        "bottom": ["jeans", "pants", "shorts"],
        "shoes": ["sneakers", "boots", "leather_shoes"],
        "accessory": ["watch", "bracelet", "necklace", "hat", "belt"]
    ]

    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()

    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = WTWColor.backgroundSub
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = WTWLayout.cornerRadius
        iv.clipsToBounds = true
        iv.image = UIImage(systemName: "camera")
        iv.tintColor = WTWColor.disabled
        iv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        iv.addGestureRecognizer(tap)
        return iv
    }()

    private lazy var typeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["上衣", "裤装", "鞋履", "配饰"])
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = WTWColor.primary
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: WTWColor.textPrimary], for: .normal)
        sc.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        return sc
    }()

    private lazy var subTypeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: subTypes["top"]!.map { $0 })
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = WTWColor.accent
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: WTWColor.textPrimary], for: .normal)
        return sc
    }()

    private lazy var sizeField: UITextField = {
        let field = UITextField()
        field.placeholder = "尺码 (S/M/L/XL)"
        field.font = WTWFont.body()
        field.textColor = WTWColor.textPrimary
        field.backgroundColor = WTWColor.backgroundSub
        field.layer.cornerRadius = WTWLayout.cornerRadius
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        field.leftViewMode = .always
        return field
    }()

    private lazy var fitSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["修身", "标准", "宽松", "Oversize"])
        sc.selectedSegmentIndex = 1
        sc.selectedSegmentTintColor = WTWColor.primary
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: WTWColor.textPrimary], for: .normal)
        return sc
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存衣物", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = WTWColor.primary
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
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
    }

    private func setupUI() {
        title = "添加衣物"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(loadingIndicator)

        contentView.addSubview(imageView)
        contentView.addSubview(typeSegment)
        contentView.addSubview(subTypeSegment)
        contentView.addSubview(sizeField)
        contentView.addSubview(fitSegment)
        contentView.addSubview(saveButton)

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

        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(200)
        }

        typeSegment.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(36)
        }

        subTypeSegment.snp.makeConstraints { make in
            make.top.equalTo(typeSegment.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(32)
        }

        sizeField.snp.makeConstraints { make in
            make.top.equalTo(subTypeSegment.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(WTWLayout.inputHeight)
        }

        fitSegment.snp.makeConstraints { make in
            make.top.equalTo(sizeField.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(36)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(fitSegment.snp.bottom).offset(WTWLayout.verticalPadding * 2)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
            make.bottom.equalToSuperview().offset(-WTWLayout.verticalPadding)
        }
    }

    @objc private func selectImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func typeChanged() {
        selectedType = types[typeSegment.selectedSegmentIndex]
        let newSubTypes = subTypes[selectedType] ?? []
        subTypeSegment.removeAllSegments()
        for (index, subType) in newSubTypes.enumerated() {
            subTypeSegment.insertSegment(withTitle: subType, at: index, animated: false)
        }
        subTypeSegment.selectedSegmentIndex = 0
    }

    @objc private func saveTapped() {
        guard let image = selectedImage else {
            showAlert(title: "请先选择图片")
            return
        }

        loadingIndicator.startAnimating()
        saveButton.isEnabled = false

        ImageUploadService.shared.processClothingImage(image) { [weak self] result in
            self?.loadingIndicator.stopAnimating()
            self?.saveButton.isEnabled = true

            switch result {
            case .success(let processed):
                self?.saveCloth(processedUrl: processed.processedUrl)
            case .failure(let error):
                self?.showAlert(title: "处理失败: \(error.localizedDescription)")
            }
        }
    }

    private func saveCloth(processedUrl: String) {
        let subTypesList = subTypes[selectedType] ?? []
        let params: [String: Any] = [
            "type": selectedType,
            "subType": subTypesList[subTypeSegment.selectedSegmentIndex],
            "size": sizeField.text ?? "M",
            "fit": ["slim", "standard", "loose", "oversize"][fitSegment.selectedSegmentIndex],
            "imageUrl": processedUrl,
            "removedBgUrl": processedUrl
        ]

        Task {
            do {
                let _: ClothResponse = try await WTWAPI.Clothes.create(params)
                await MainActor.run { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.showAlert(title: "保存失败")
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

extension AddClothingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            imageView.image = image
        }
        picker.dismiss(animated: true)
    }
}