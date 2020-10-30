//
//  ViewController.swift
//  DiffableDataSourceTest
//
//  Created by Alex Marshall on 10/30/20.
//

import UIKit
let cellIdentifier = "testRecordCell"

struct TestRecord:Hashable {
    let identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    static func == (lhs: TestRecord, rhs: TestRecord) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    var timeStamp: Date
    init(daysBack: Int){
        self.timeStamp = Calendar.current.date(byAdding: .day, value: -1*daysBack, to: Date())!
    }
}
class YearMonthDay: Hashable {
    let year: Int
    let month: Int
    let day: Int
    var records: [TestRecord]
    
    init(year: Int, month: Int, day: Int, records:[TestRecord]) {
        self.year = year
        self.month = month
        self.day = day
        self.records = records
    }

    init(date: Date, records:[TestRecord]) {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        self.year = comps.year!
        self.month = comps.month!
        self.day = comps.day!
        self.records = records
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(year)
        hasher.combine(month)
        hasher.combine(day)
    }
    var date: Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        return Calendar.current.date(from: dateComponents)!
    }

    static func == (lhs: YearMonthDay, rhs: YearMonthDay) -> Bool {
        return lhs.year == rhs.year && lhs.month == rhs.month && lhs.day == rhs.day
    }

    static func < (lhs: YearMonthDay, rhs: YearMonthDay) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        } else {
            if lhs.month != rhs.month {
                return lhs.month < rhs.month
            } else {
                return lhs.day < rhs.day
            }
        }
    }
}
class Cell:UICollectionViewCell {
}
class TimelineViewController: UICollectionViewController {

    private lazy var dataSource = makeDataSource()
    
    fileprivate typealias DataSource = UICollectionViewDiffableDataSource<YearMonthDay,TestRecord>
    fileprivate typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<YearMonthDay,TestRecord>
    
    public var data: [YearMonthDay:[TestRecord]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.register(Cell.self, forCellWithReuseIdentifier: cellIdentifier)
        data = fetchData()
        applySnapshot()
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.delegate = self
        }
    }
    private func fetchData() -> [YearMonthDay:[TestRecord]] {
        
        var data: [YearMonthDay:[
            TestRecord]] = [:]
        var testRecords:[TestRecord] = []
        for i in 0...6{
            let testRecord = TestRecord(daysBack: i*2)
            testRecords.append(testRecord)
        }
        for record in testRecords {
            let ymd = YearMonthDay(date:record.timeStamp,records: [])
            if var day = data[ymd] {
                day.append(record)
            } else {
                data[ymd] = [record]
            }
        }
        return data
    }

}
extension TimelineViewController {
    
    fileprivate func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: self.collectionView,
            cellProvider: { (collectionView, indexPath, testRecord) ->
              UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
                cell.backgroundColor = .black
                return cell
            })
        return dataSource
    }
    func applySnapshot(animatingDifferences: Bool = true) {
        // 2
        var snapshot = DataSourceSnapshot()
        for (ymd,records) in data {
              snapshot.appendSections([ymd])
              snapshot.appendItems(records,toSection: ymd)
        }
        dataSource.apply(snapshot)
    }
}
extension TimelineViewController: PinterestLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        return CGFloat(10)
    }
}
//extension TimelineViewController: TimelineLayoutDelegate {
//    func collectionView(_ collectionView: UICollectionView, dateAtIndexPath indexPath: IndexPath) -> Date? {
//        let ymd = dataSource.itemIdentifier(for: indexPath)
//        return Date()
//    }
//}
