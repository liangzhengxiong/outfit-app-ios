import UIKit
import SnapKit

class OutfitCalendarViewController: UIViewController {

    private var records: [CalendarRecordItem] = []
    private var selectedDate = Date()

    private lazy var calendarView: UIView = {
        let view = UIView()
        view.backgroundColor = WTWColor.secondary
        return view
    }()

    private lazy var monthLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.cardTitle()
        label.textColor = WTWColor.textPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = WTWColor.primary
        button.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = WTWColor.primary
        button.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
        return button
    }()

    private lazy var weekdayStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        for day in weekdays {
            let label = UILabel()
            label.text = day
            label.font = WTWFont.caption()
            label.textColor = WTWColor.disabled
            label.textAlignment = .center
            stack.addArrangedSubview(label)
        }
        return stack
    }()

    private lazy var daysStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private lazy var recordLabel: UILabel = {
        let label = UILabel()
        label.font = WTWFont.body()
        label.textColor = WTWColor.textPrimary
        label.text = "今日穿搭"
        return label
    }()

    private lazy var recordCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 130)
        layout.minimumInteritemSpacing = WTWLayout.cardSpacing
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(CalendarRecordCell.self, forCellWithReuseIdentifier: "CalendarRecordCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private lazy var emptyView: UILabel = {
        let label = UILabel()
        label.font = WTWFont.caption()
        label.textColor = WTWColor.disabled
        label.text = "今日暂无穿搭记录"
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCalendar()
        fetchRecords()
    }

    private func setupUI() {
        title = "穿搭日历"
        view.backgroundColor = WTWColor.secondary

        view.addSubview(calendarView)
        calendarView.addSubview(monthLabel)
        calendarView.addSubview(prevButton)
        calendarView.addSubview(nextButton)
        calendarView.addSubview(weekdayStack)
        calendarView.addSubview(daysStack)
        view.addSubview(recordLabel)
        view.addSubview(recordCollectionView)
        view.addSubview(emptyView)

        calendarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(WTWLayout.verticalPadding)
            make.leading.trailing.equalToSuperview().inset(WTWLayout.horizontalPadding)
            make.height.equalTo(280)
        }

        monthLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
        }

        prevButton.snp.makeConstraints { make in
            make.centerY.equalTo(monthLabel)
            make.leading.equalToSuperview().offset(12)
            make.size.equalTo(44)
        }

        nextButton.snp.makeConstraints { make in
            make.centerY.equalTo(monthLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.size.equalTo(44)
        }

        weekdayStack.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(24)
        }

        daysStack.snp.makeConstraints { make in
            make.top.equalTo(weekdayStack.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-12)
        }

        recordLabel.snp.makeConstraints { make in
            make.top.equalTo(calendarView.snp.bottom).offset(WTWLayout.verticalPadding)
            make.leading.equalToSuperview().offset(WTWLayout.horizontalPadding)
        }

        recordCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recordLabel.snp.bottom).offset(WTWLayout.cardSpacing)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(130)
        }

        emptyView.snp.makeConstraints { make in
            make.center.equalTo(recordCollectionView)
        }
    }

    private func updateCalendar() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        monthLabel.text = formatter.string(from: selectedDate)

        daysStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        guard let firstDayOfMonth = calendar.date(from: components) else { return }

        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30

        var currentWeek: UIStackView?

        for day in 1...daysInMonth {
            if day == 1 || (day + weekday - 1) % 7 == 1 {
                currentWeek = UIStackView()
                currentWeek?.axis = .horizontal
                currentWeek?.distribution = .fillEqually
                daysStack.addArrangedSubview(currentWeek!)
            }

            let dayView = createDayView(day: day)
            currentWeek?.addArrangedSubview(dayView)
        }

        if let lastWeek = daysStack.arrangedSubviews.last as? UIStackView,
           lastWeek.arrangedSubviews.count < 7 {
            for _ in 0..<(7 - lastWeek.arrangedSubviews.count) {
                let spacer = UIView()
                lastWeek.addArrangedSubview(spacer)
            }
        }
    }

    private func createDayView(day: Int) -> UIView {
        let view = UIView()
        view.layer.cornerRadius = 4

        let label = UILabel()
        label.text = "\(day)"
        label.font = WTWFont.body()
        label.textAlignment = .center

        let today = Calendar.current.component(.day, from: Date())
        let currentMonth = Calendar.current.component(.month, from: selectedDate)
        let todayMonth = Calendar.current.component(.month, from: Date())

        if day == today && currentMonth == todayMonth {
            view.backgroundColor = WTWColor.accent
            label.textColor = .white
        } else {
            label.textColor = WTWColor.textPrimary
        }

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        return view
    }

    @objc private func prevMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        updateCalendar()
        fetchRecords()
    }

    @objc private func nextMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        updateCalendar()
        fetchRecords()
    }

    private func fetchRecords() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startDate = formatter.string(from: selectedDate)
        let endDate = formatter.string(from: selectedDate)

        Task {
            do {
                let response = try await WTWAPI.Outfits.calendar(startDate: startDate, endDate: endDate)
                records = response.records
                recordCollectionView.reloadData()
                emptyView.isHidden = !records.isEmpty
            } catch {
                print("Failed to fetch calendar: \(error)")
            }
        }
    }
}

extension OutfitCalendarViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return records.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarRecordCell", for: indexPath) as! CalendarRecordCell
        cell.configure(with: records[indexPath.item])
        return cell
    }
}

class CalendarRecordCell: UICollectionViewCell {
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

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = WTWColor.disabled.withAlphaComponent(0.2)
        imageView.layer.cornerRadius = 4

        nameLabel.font = WTWFont.caption()
        nameLabel.textColor = WTWColor.textPrimary
        nameLabel.textAlignment = .center

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(80)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(4)
        }
    }

    func configure(with record: CalendarRecordItem) {
        nameLabel.text = record.outfit?.name ?? "穿搭"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}