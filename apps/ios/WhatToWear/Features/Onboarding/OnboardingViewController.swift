import UIKit
import SnapKit

class OnboardingViewController: UIViewController {

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "tshirt.fill",
            title: "拍照存衣",
            subtitle: "轻松上传衣物，AI自动抠图"
        ),
        OnboardingPage(
            image: "sparkles",
            title: "智能搭配",
            subtitle: "根据天气和风格智能推荐穿搭"
        ),
        OnboardingPage(
            image: "person.fill",
            title: "3D上身试穿",
            subtitle: "预览穿搭效果，满意再出门"
        )
    ]

    private var currentPage = 0

    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = pages.count
        pc.currentPage = 0
        pc.pageIndicatorTintColor = WTWColor.disabled
        pc.currentPageIndicatorTintColor = WTWColor.primary
        return pc
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.delegate = self
        return sv
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        return stack
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("下一步", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = WTWFont.button()
        button.backgroundColor = WTWColor.primary
        button.layer.cornerRadius = WTWLayout.cornerRadius
        button.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        return button
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("跳过", for: .normal)
        button.setTitleColor(WTWColor.disabled, for: .normal)
        button.titleLabel?.font = WTWFont.caption()
        button.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPages()
    }

    private func setupUI() {
        view.backgroundColor = WTWColor.secondary

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(pageControl)
        view.addSubview(nextButton)
        view.addSubview(skipButton)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(400)
        }

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        pageControl.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.bottom.equalTo(skipButton.snp.top).offset(-16)
            make.height.equalTo(WTWLayout.buttonHeight)
        }

        skipButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-WTWLayout.verticalPadding)
        }
    }

    private func setupPages() {
        for page in pages {
            let pageView = createPageView(page)
            contentStack.addArrangedSubview(pageView)
            pageView.snp.makeConstraints { make in
                make.width.equalTo(view)
            }
        }
    }

    private func createPageView(_ page: OnboardingPage) -> UIView {
        let container = UIView()

        let imageView = UIImageView(image: UIImage(systemName: page.image))
        imageView.tintColor = WTWColor.primary
        imageView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = page.title
        titleLabel.font = WTWFont.title()
        titleLabel.textColor = WTWColor.textPrimary
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = page.subtitle
        subtitleLabel.font = WTWFont.body()
        subtitleLabel.textColor = WTWColor.disabled
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        container.addSubview(imageView)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)

        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.size.equalTo(150)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
        }

        return container
    }

    @objc private func nextTapped() {
        if currentPage < pages.count - 1 {
            currentPage += 1
            let offsetX = CGFloat(currentPage) * scrollView.bounds.width
            scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
            pageControl.currentPage = currentPage
        } else {
            goToMain()
        }
        updateButtonTitle()
    }

    @objc private func skipTapped() {
        goToMain()
    }

    private func updateButtonTitle() {
        if currentPage == pages.count - 1 {
            nextButton.setTitle("开始使用", for: .normal)
        } else {
            nextButton.setTitle("下一步", for: .normal)
        }
    }

    private func goToMain() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        let mainVC = MainTabBarController()
        mainVC.modalPresentationStyle = .fullScreen
        present(mainVC, animated: true)
    }
}

extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        if page != currentPage && page >= 0 && page < pages.count {
            currentPage = page
            pageControl.currentPage = page
            updateButtonTitle()
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let subtitle: String
}