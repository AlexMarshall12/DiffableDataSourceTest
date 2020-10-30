//
//  TimelineLayout.swift
//  DiffableDataSourceTest
//
//  Created by Alex Marshall on 10/30/20.
//

import UIKit

protocol TimelineLayoutDelegate: class {
    func collectionView(_ collectionView: UICollectionView, dateAtIndexPath indexPath: IndexPath) -> Date?
}

struct MonthBound {
    var start: CGFloat?
    var end: CGFloat?
}

class TimelineLayout: UICollectionViewFlowLayout {
    
    weak var delegate: TimelineLayoutDelegate!
    
    enum Element: String {
        case day
        case month
        case year
        var id: String {
            return self.rawValue
        }
        var kind: String {
            return "Kind\(self.rawValue.capitalized)"
        }
    }
    private var oldBounds = CGRect.zero
    private var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
    private var contentWidth = CGFloat()
    private var cache = [Element: [IndexPath: UICollectionViewLayoutAttributes]]()
    private var monthHeight: CGFloat = 19
    private var yearHeight: CGFloat = 11
    private var dayHeight: CGFloat = 30
    private var cellWidth: CGFloat = 2.5
    private var collectionViewStartY: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        return collectionView.bounds.minY
    }
    private var collectionViewHeight: CGFloat {
        return collectionView!.frame.height
    }
    override public var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: collectionViewHeight)
    }
}

extension TimelineLayout {
    override public func prepare() {
        guard let collectionView = collectionView,
            cache.isEmpty else {
                return
        }
        collectionView.decelerationRate = .fast
        updateInsets()
        cache.removeAll(keepingCapacity: true)
        cache[.year] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.month] = [IndexPath: UICollectionViewLayoutAttributes]()
        cache[.day] = [IndexPath: UICollectionViewLayoutAttributes]()
        oldBounds = collectionView.bounds
        var timelineStart: Date?
        var timelineEnd: Date?
        for item in 0 ..< collectionView.numberOfItems(inSection: 0) {
            let cellIndexPath = IndexPath(item: item, section: 0)
            guard let cellDate = delegate.collectionView(collectionView, dateAtIndexPath: cellIndexPath) else {
                return
            }
            if item == 0 {
                let firstDate = cellDate
                timelineStart = Calendar.current.startOfDay(for: firstDate)
            }
            if item == collectionView.numberOfItems(inSection: 0) - 1 {
                timelineEnd = cellDate
            }
            
            let startX = CGFloat(cellDate.days(from: timelineStart!)) * cellWidth
            let dayCellattributes = UICollectionViewLayoutAttributes(forCellWith: cellIndexPath)
            dayCellattributes.frame = CGRect(x: startX, y: collectionViewStartY + yearHeight + monthHeight, width: cellWidth, height: dayHeight)
            cache[.day]?[cellIndexPath] = dayCellattributes
            contentWidth = max(startX + cellWidth,contentWidth)
        }
        ///TODO - what if there are no items in the section....
        guard let timelineLabelsBegin = timelineStart?.startOfMonth() else { return }
        var date: Date = timelineLabelsBegin
        
        let initalOffset = CGFloat((timelineStart?.days(from: date))!) * cellWidth
        
        var monthOffset: CGFloat = 0
        var monthIndex: Int = 0
        var yearIndex: Int = 0
        
        while date <= timelineEnd! {
            
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: date)?.count
            let monthWidth = cellWidth * CGFloat(daysInMonth!)
            //let monthIndex = date.months(from: timelineStart!)
            
            let monthLabelIndexPath = IndexPath(item: monthIndex, section: 0)
            let monthLabelAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Element.month.kind, with: monthLabelIndexPath)
            let startX = monthOffset - initalOffset
            monthLabelAttributes.frame = CGRect(x: startX, y: collectionViewStartY + yearHeight, width: monthWidth, height: monthHeight)
            cache[.month]?[monthLabelIndexPath] = monthLabelAttributes
            monthOffset += monthWidth
            
            if Calendar.current.component(.month, from: date) == 1 || yearIndex == 0 {
                //draw year
                //let year = Calendar.current.component(.year, from: date)
                //let yearIndex = date.years(from: timelineStart!)
                let daysFromStartOfYear = date.days(from: date.startOfYear())
                let startYearX = startX - CGFloat(daysFromStartOfYear) * cellWidth
                let yearLabelIndexPath = IndexPath(item: yearIndex, section: 0)
                let yearLabelAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Element.year.kind, with: yearLabelIndexPath)
                yearLabelAttributes.frame = CGRect(x: startYearX, y: collectionViewStartY, width: CGFloat(30), height: yearHeight)
                cache[.year]?[yearLabelIndexPath] = yearLabelAttributes
                yearIndex += 1
            }
            date = Calendar.current.date(byAdding: .month, value: 1, to: date)!
            monthIndex += 1
        }
    }
}


extension TimelineLayout {
    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case Element.year.kind:
            return cache[.year]?[indexPath]
        default:
            return cache[.month]?[indexPath]
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        visibleLayoutAttributes.removeAll(keepingCapacity: true)

        if let yearAttrs = cache[.year], let monthAttrs = cache[.month], let dayAttrs = cache[.day] {
            for (_, attributes) in yearAttrs {
                visibleLayoutAttributes.append(self.translatedYearLabels(from: attributes))
            }
            for (_, attributes) in monthAttrs {
                visibleLayoutAttributes.append(attributes)
            }
            for (_, attributes) in dayAttrs {
                visibleLayoutAttributes.append(self.shiftedAttributes(from: attributes))
            }
        }
        return visibleLayoutAttributes
    }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = cache[.day]?[indexPath] else { fatalError("No attributes cached") }
        
        return shiftedAttributes(from: attributes)
    }

    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if oldBounds.size != newBounds.size {
            cache.removeAll(keepingCapacity: true)
        }
        return true
    }
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if context.invalidateDataSourceCounts { cache.removeAll(keepingCapacity: true) }
        super.invalidateLayout(with: context)
    }
}

extension TimelineLayout {
    //DayCell Animations
    
    private func updateInsets() {
        guard let collectionView = collectionView else { return }
        collectionView.contentInset.left = (collectionView.bounds.size.width - cellWidth) / 2
        collectionView.contentInset.right = (collectionView.bounds.size.width - cellWidth) / 2
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset) }
        let midX: CGFloat = collectionView.bounds.size.width / 2
        guard let closestAttribute = findClosestAttributes(toXPosition: proposedContentOffset.x + midX) else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset) }
        return CGPoint(x: closestAttribute.center.x - midX, y: proposedContentOffset.y)
    }
    
    private func findClosestAttributes(toXPosition xPosition: CGFloat) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else { return nil }
        let searchRect = CGRect(
            x: xPosition - collectionView.bounds.width, y: collectionView.bounds.minY,
            width: collectionView.bounds.width * 2, height: collectionView.bounds.height
        )
        let closestAttributes = layoutAttributesForElements(in: searchRect)?.min(by: { abs($0.center.x - xPosition) < abs($1.center.x - xPosition) })
        return closestAttributes
    }
    private var continuousFocusedIndex: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let offset = collectionView.bounds.width / 2 + collectionView.contentOffset.x - cellWidth / 2
        return offset / cellWidth
    }
    
    private func shiftedAttributes(from attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let attributes = attributes.copy() as? UICollectionViewLayoutAttributes else { fatalError("Couldn't copy attributes") }
        let roundedFocusedIndex = round(continuousFocusedIndex)
        let offset = (cache[.day]?[attributes.indexPath]?.frame.minX)!/cellWidth
        if Int(offset) == Int(roundedFocusedIndex){
            attributes.transform = CGAffineTransform(scaleX: 10, y: 1)
//        } else {
//            let translationDirection: CGFloat = attributes.indexPath.item < Int(roundedFocusedIndex) ? -1 : 1
//            attributes.transform = CGAffineTransform(translationX: translationDirection * 12, y: 0)
        }
        return attributes
    }
}

extension TimelineLayout {
    private func translatedYearLabels(from attributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let attributes = attributes.copy() as? UICollectionViewLayoutAttributes else { fatalError("Couldn't copy attributes") }
        guard let collectionView = collectionView else {
            return attributes
        }
        var adjust: CGFloat = 0
        if collectionView.bounds.minX > attributes.frame.minX {
            //put frame on far left of screen - equal to the beginning of the collection view
            adjust = collectionView.bounds.minX - attributes.frame.minX
            //This makes it move with the scrolling
            adjust = adjust - collectionView.contentOffset.x - 50
            //If it moves it before screen, move it back to beginning of content view
            if attributes.frame.minX + adjust < collectionView.bounds.minX {
                adjust = collectionView.bounds.minX - attributes.frame.minX
            }
            //So that it doesn't move more than 1 year and doesn't run into any other date...
            adjust = min(adjust,365*2.5-attributes.frame.width)
            attributes.transform = CGAffineTransform(translationX: adjust, y: 0)
        }
        return attributes
    }
}


extension Date {
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }

    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: 1, to: self.startOfMonth())!
    }
    
    func daysInMonth() -> Int {
        return Calendar.current.range(of: .day, in: .month, for: self)!.count
    }
    
    func startOfYear() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Calendar.current.startOfDay(for: self)))!
    }
}
