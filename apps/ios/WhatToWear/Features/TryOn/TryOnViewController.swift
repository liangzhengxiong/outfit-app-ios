import UIKit
import SnapKit

class TryOnViewController: UIViewController {

    private var is3DMode = true
    private var currentOutfit: OutfitItem?
    private var scale: CGFloat = 1.0
    private var shoulderOffset: CGFloat = 0
    private var lengthOffset: CGFloat = 0

    private lazy var modeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["2D平铺", "3D上身"])
        sc.selectedSegmentIndex = 1
        sc.selectedSegmentTintColor = WTWColor.primary
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: WTWColor.textPrimary], for: .normal)
        sc.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        return sc
    }()

    private lazy var previewView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.backgroundSub
        view.layer.cornerRadius = WTWLayout.cornerRadius
        view.clipsToBounds = true
        return view
    }()

    private lazy var modelImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(systemName: "person")
        iv.tintColor = WTWColor.disabled
        return iv
    }()

    private lazy var clothingImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var controlsView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.secondary
        return view
    }()

    private lazy var scaleSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.8
        slider.maximumValue = 1.2
        slider.value = 1.0
        slider.tintColor = WTWColor.primary
        slider.addTarget(self, action: #selector(scaleChanged), for: .valueChanged)
        return slider
    }()

    private lazy var shoulderSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = -20
        slider.maximumValue = 20
        slider.value = 0
        slider.tintColor = WTWColor.primary
        slider.addTarget(self, action: #selector(shoulderChanged), for: .valueChanged)
        return slider
    }()

    private lazy var lengthSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = -30
        slider.maximumValue = 30
        slider.value = 0
        slider.tintColor = WTWColor.primary
        slider.addTarget(self, action: #selector(lengthChanged), for: .valueChanged)
        return slider
    }()

    private lazy var scaleLabel = createSliderLabel(title: "缩放")
    private lazy var shoulderLabel = createSliderLabel(title: "肩线")
    private lazy var lengthLabel = createSliderLabel(title: "衣长")

    private lazy var actionStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = WTWLayout.cardSpacing
        return stack
    }()

    private lazy var changeButton: UIButton = {
        let button = createActionButton(title: "换一套", color: WTWColor.primary)
        button.addTarget(self, action: #selector(changeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var saveButton: UIButton = {
        let button = createActionButton(title: "保存", color: WTWColor.accent)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()

    private lazy var calendarButton: UIButton = {
        let button = createActionButton(title: "加入日历", color: WTWColor.primary)
        button.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }

    private func setupUI() {
        title = "上身试穿"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(modeSegment)
        view.addSubview(previewView)
        previewView.addSubview(modelImageView)
        previewView.addSubview(clothingImageView)
        view.addSubview(controlsView)
        view.addSubview(actionStack)

        let scaleRow = createSliderRow(label: scaleLabel, slider: scaleSlider)
        let shoulderRow = createSliderRow(label: shoulderLabel, slider: shoulderSlider)
        let lengthRow = createSliderRow(label: lengthLabel, slider: lengthSlider)

        let controlsStack = UIStackView(arrangedSubviews: [scaleRow, shoulderRow, lengthRow])
        controlsStack.axis = .vertical
        controlsStack.spacing = WTWLayout.listSpacing
        controlsView.addSubview(controlsStack)

        actionStack.addArrangedSubview(changeButton)
        actionStack.addArrangedSubview(saveButton)
        actionStack.addArrangedSubview(calendarButton)

        modeSegment.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(36)
        }

        previewView.snp.makeConstraints { make in
            make.top.equalTo(modeSegment.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(view.snp.width).multipliedBy(1.3)
        }

        modelImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.6)
            make.height.equalTo(modelImageView.snp.width).multipliedBy(1.5)
        }

        clothingImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(modelImageView).multipliedBy(scale)
            make.height.equalTo(modelImageView).multipliedBy(scale)
            make.centerX.equalTo(modelImageView).offset(shoulderOffset)
            make.top.equalTo(modelImageView).offset(lengthOffset)
        }

        controlsView.snp.makeConstraints { make in
            make.top.equalTo(previewView.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(actionStack.snp.top).offset(-WTWLayout.cardSpacing)
        }

        controlsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: WTWLayout.verticalPadding, left: WTWLayout.horizontalPadding, bottom: WTWLayout.verticalPadding, right: WTWLayout.horizontalPadding))
        }

        actionStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-WTWLayout.verticalPadding)
            make.height.equalTo(WTWLayout.buttonHeight)
        }
    }

    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        previewView.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        previewView.addGestureRecognizer(pinchGesture)
    }

    private func createSliderLabel(title: String) -> UILabel {
        let label = UILabel()
        label.font = WTWFont.caption()
        label.textColor = WTWColor.textPrimary
        label.text = title
        label.snp.makeConstraints { $0.width.equalTo(40) }
        return label
    }

    private func createSliderRow(label: UILabel, slider: UISlider) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [label, slider])
        row.axis = .horizontal
        row.spacing = WTWLayout.cardSpacing
        return row
    }

    private func createActionButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = color
        button.layer.cornerRadius = WTWLayout.cornerRadius
        return button
    }

    @objc private func modeChanged() {
        is3DMode = modeSegment.selectedSegmentIndex == 1
    }

    @objc private func scaleChanged() {
        scale = CGFloat(scaleSlider.value)
        updateClothingConstraints()
    }

    @objc private func shoulderChanged() {
        shoulderOffset = CGFloat(shoulderSlider.value)
        updateClothingConstraints()
    }

    @objc private func lengthChanged() {
        lengthOffset = CGFloat(lengthSlider.value)
        updateClothingConstraints()
    }

    private func updateClothingConstraints() {
        clothingImageView.snp.updateConstraints { make in
            make.width.equalTo(modelImageView).multipliedBy(scale)
            make.height.equalTo(modelImageView).multipliedBy(scale)
            make.centerX.equalTo(modelImageView).offset(shoulderOffset)
            make.top.equalTo(modelImageView).offset(lengthOffset)
        }
    }

    @objc private func changeTapped() {
        Task {
            do {
                let response = try await WTWAPI.Outfits.generate(style: nil, weather: nil, occasion: nil)
                currentOutfit = response.outfit
                updatePreview()
            } catch {
                print("Failed to generate outfit: \(error)")
            }
        }
    }

    @objc private func saveTapped() {
        showToast("穿搭已保存")
    }

    @objc private func calendarTapped() {
        showToast("已加入穿搭日历")
    }

    private func updatePreview() {
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard is3DMode else { return }
        let translation = gesture.translation(in: previewView)
        if gesture.state == .changed {
            shoulderOffset += translation.x * 0.1
            lengthOffset += translation.y * 0.1
            shoulderSlider.value = Float(shoulderOffset)
            lengthSlider.value = Float(lengthOffset)
            updateClothingConstraints()
            gesture.setTranslation(.zero, in: previewView)
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard is3DMode else { return }
        if gesture.state == .changed {
            scale *= gesture.scale
            scale = max(0.8, min(1.2, scale))
            scaleSlider.value = Float(scale)
            updateClothingConstraints()
            gesture.scale = 1.0
        }
    }

    private func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.font = WTWFont.caption()
        toast.textColor = .white
        toast.backgroundColor = WTWColor.textPrimary.withAlphaComponent(0.9)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 4
        toast.clipsToBounds = true

        view.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(actionStack.snp.top).offset(-20)
            make.width.equalTo(120)
            make.height.equalTo(32)
        }

        UIView.animate(withDuration: 0.3, delay: 1.5, options: []) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }
}