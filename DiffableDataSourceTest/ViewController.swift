//
//  ViewController.swift
//  DiffableDataSourceTest
//
//  Created by Alex Marshall on 10/30/20.
//

import UIKit
let cellIdentifier = "testRecordCell"

struct Record:Hashable {
    let identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    static func == (lhs: Record, rhs: Record) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    var timeStamp: Date
    init(daysBack: Int){
        self.timeStamp = Calendar.current.date(byAdding: .day, value: -1*daysBack, to: Date())!
    }
}
class Cell:UICollectionViewCell {
}

class Section: Hashable {
  var id = UUID()
  // 2
  var records:[Record]
  
  init(records:[Record]) {
    self.records = records
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func == (lhs: Section, rhs: Section) -> Bool {
    lhs.id == rhs.id
  }
}

extension Section {
  static var allSections: [Section] = [
    Section(records: [
      Record(daysBack: 5),Record(daysBack: 6)
    ]),
    Section(records: [
      Record(daysBack: 3)
    ])
    ]
}

class ViewController: UICollectionViewController {

    private lazy var dataSource = makeDataSource()
    private var sections = Section.allSections

    fileprivate typealias DataSource = UICollectionViewDiffableDataSource<Section,Record>
    fileprivate typealias DataSourceSnapshot = NSDiffableDataSourceSnapshot<Section,Record>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.register(Cell.self, forCellWithReuseIdentifier: cellIdentifier)
        applySnapshot()
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.delegate = self
        }
    }
}
extension ViewController {
    
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
        snapshot.appendSections(sections)
        sections.forEach { section in
          snapshot.appendItems(section.records, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}
extension ViewController: PinterestLayoutDelegate {
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
