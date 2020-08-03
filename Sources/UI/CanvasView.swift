//
//  CanvasView.swift
//  Canvas
//
//  Created by scchn on 2020/7/21.
//  Copyright © 2020 scchn. All rights reserved.
//

import Cocoa

@objc public protocol CanvasViewDelegate: AnyObject {
    // Drawing Session
    @objc optional func canvasView(_ canvasView: CanvasView, didFinishSession item: Shape)
    @objc optional func canvasViewDidCancelSession(_ canvasView: CanvasView)
    // Selection
    @objc optional func canvasView(_ canvasView: CanvasView, didSelect items: [Shape])
    @objc optional func canvasView(_ canvasView: CanvasView, didDeselect items: [Shape])
    // Modification
    @objc optional func canvasView(_ canvasView: CanvasView, didEdit item: Shape, indexPath: IndexPath)
    @objc optional func canvasView(_ canvasView: CanvasView, didMove item: Shape)
    @objc optional func canvasView(_ canvasView: CanvasView, didRotate item: Shape)
    // Menu
    @objc optional func menu(for canvasView: CanvasView) -> NSMenu?
    @objc optional func canvasView(_ canvasView: CanvasView, menuFor item: Shape) -> NSMenu?
}

extension CanvasView {

    @objc public enum PointStyle: Int, CaseIterable {
        case circle
        case square
    }
    
    enum State {
        case idle
        case select(CGRect)
        case drawing(Shape)
        
        case onAnchor(Shape)
        case movingAnchor(Shape)
        
        case onRotator(Shape)
        case movingRotator(Shape)
        
        case onItem(Shape, CGPoint)
        case movingItem(Shape, CGPoint)
        
        case onPoint(Shape, IndexPath)
        case movingPoint(Shape, IndexPath)
        
        fileprivate var drawingItem: Shape? {
            guard case .drawing(let item) = self else { return nil }
            return item
        }
    }
    
    enum MouseAction {
        case idle
        case down
        case drag
    }
    
}

public final class CanvasView: NSView {
    
    // MARK: - Life Cycle
    
    private var state: State = .idle
    private var mouseAction: MouseAction = .idle
    
    public weak var delegate: CanvasViewDelegate?
    
    public private(set) var items: [Shape] = []
    public var currentItem: Shape? { state.drawingItem }
    public var selectedItems: [Shape] { items.reversed().filter { $0.isSelected } }
    public var singleSelection: Shape? { selectedItems.count == 1 ? selectedItems.first : nil }
    public var selectionIndexes: IndexSet { IndexSet(selectedItems.compactMap(items.firstIndex(of:))) }
    
    // MARK: - Settings
    
    public var backgroundColor: NSColor = .clear
    public var selectorBorderColor: NSColor = .lightGray
    public var selectorFillColor: NSColor = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
    public var strokeColor: NSColor = .black
    public var fillColor: NSColor = .clear
    public var highlightedColor: NSColor = .selectedMenuItemColor
    public var selectionRange: CGFloat = 5
    public var pointStyle: PointStyle = .circle {
        didSet { refresh() }
    }
    public var isSelectable: Bool = true {
        didSet { deselectAllItems() }
    }
    public var isRotationEnabled: Bool = false {
        didSet { refresh() }
    }
    public var isMagnetEnabled: Bool = false {
        didSet { refresh() }
    }
    public var isAuxToolEnabled: Bool = false
    
    private var rotatorRadius: CGFloat { selectionRange * 2.5 }
    
    // MARK: - Life Cycle
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    public init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    private func commonInit() {
    }
    
    // MARK: - Drawing
    
    private func refresh() {
        needsDisplay = true
    }
    
    public override func draw(_ rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        
        ctx.setFillColor(backgroundColor.cgColor)
        ctx.fill(rect)
        
        let allItems: [Shape] = {
            guard case .drawing(let item) = state else { return items }
            return items + [item]
        }()
        
        for item in allItems {
            item.draw(with: rect, in: ctx)
        }

        switch state {
        case .movingItem: break
        case .drawing(let item) :
            if mouseAction == .drag && isAuxToolEnabled && item.supportsAuxTool,
                let indexPath = item.endIndexPath {
                drawAuxTool(for: item, with: indexPath, connected: false, in: ctx)
            }
            if isMagnetEnabled {
                drawMagnetPoints(for: item, in: ctx)
            }
        case .movingPoint(let item, let indexPath):
            if isAuxToolEnabled && item.supportsAuxTool {
                drawAuxTool(for: item, with: indexPath, connected: true, in: ctx)
            }
            if isMagnetEnabled {
                drawMagnetPoints(for: item, in: ctx)
            }
        default:
            for item in selectedItems {
                var markedIndexPath: IndexPath?
                if case .onPoint(let mItem, let indexPath) = state, mItem == item {
                    markedIndexPath = indexPath
                }
                drawPoints(for: item, pointStyle: pointStyle, rotationAngle: item.rotationAngle, highlightedIndexPath: markedIndexPath, in: ctx)
                if selectedItems.count == 1 {
                    if isRotationEnabled {
                        var highlightAnchor = false
                        var highlightRotator = false
                        switch state {
                        case .onRotator, .movingRotator:
                            highlightRotator = true
                        case .onAnchor, .movingAnchor:
                            highlightAnchor = true
                        default:
                            break
                        }
                        drawAnchor(for: item, pointStyle: .circle, rotationAngle: item.rotationAngle, isHighlighted: highlightAnchor, in: ctx)
                        drawRotator(for: item, isHighlighted: highlightRotator, in: ctx)
                    }
                }
            }
        }
        
        if case .select(let rect) = state {
            drawSelector(with: rect, in: ctx)
        }
    }
    
    // MARK: - Mouse Events
    
    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        mouseAction = .down
        
        switch state {
        case .idle where isSelectable:
            if isRotationEnabled, let item = onRotatorTest(location) {
                state = .onRotator(item)
            } else if isRotationEnabled, let item = onAnchorTest(location) {
                state = .onAnchor(item)
            } else if let (item, indexPath) = onPointTest(location) {
                selectItems([item], byExtendingSelection: false)
                state = .onPoint(item, indexPath)
            } else if let item = onItemTest(location) {
                if !selectedItems.contains(item) {
                    selectItems([item], byExtendingSelection: false)
                }
                state = .onItem(item, location)
            } else {
                let origin = CGPoint(x: round(location.x) + 0.5, y: round(location.y) + 0.5)
                let rect = CGRect(origin: origin, size: .zero)
                deselectAllItems()
                state = .select(rect)
            }
        case .drawing(let item):
            if isMagnetEnabled, let (_, magnetPoint) = magnetTest(item: item, at: location) {
                item.push(magnetPoint)
            } else {
                item.push(location)
            }
            if item.layout.last?.count == 1 {
                item.push(location)
            }
        default:
            break
        }
        
        refresh()
    }
    
    public override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        let location = convert(event.locationInWindow, from: nil)
        
        mouseAction = .drag
        
        switch state {
        case .select(var rect):
            let line = Line(from: rect.origin, to: location)
            let size = CGSize(width: round(line.dx), height: round(line.dy))
            rect.size = size
            selectItems(with: rect)
            state = .select(rect)
        case .drawing(let item):
            if isMagnetEnabled, let (_, magnetPoint) = magnetTest(item: item, at: location) {
                item.updateLast(magnetPoint)
            } else {
                item.updateLast(location)
            }
            
        case .onRotator(let item): fallthrough
        case .movingRotator(let item):
            guard let center = item.rotationCenter else { break }
            let radians = Line(from: center, to: location).angle
            item.rotate(radians)
            state = .movingRotator(item)
            delegate?.canvasView?(self, didRotate: item)
            
        case .onAnchor(let item): fallthrough
        case .movingAnchor(let item):
            let anchor = anchoringTest(item: item, location: location)
            item.anchor(at: anchor)
            state = .movingAnchor(item)
            
        case .onPoint(let item, let indexPath): fallthrough
        case .movingPoint(let item, let indexPath):
            if isMagnetEnabled, let (_, magnetPoint) = magnetTest(item: item, at: location) {
                item.update(magnetPoint, at: indexPath)
            } else {
                item.update(location, at: indexPath)
            }
            state = .movingPoint(item, indexPath)
            delegate?.canvasView?(self, didEdit: item, indexPath: indexPath)
            
        case .onItem(let item, let lastLocation): fallthrough
        case .movingItem(let item, let lastLocation):
            let offset = Line(from: lastLocation, to: location).offset
            selectedItems.forEach { $0.translate(offset) }
            state = .movingItem(item, location)
            delegate?.canvasView?(self, didMove: item)
            
        default:
            break
        }
        
        refresh()
    }
    
    public override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
//        let location = convert(event.locationInWindow, from: nil)
        
        mouseAction = .idle
        
        switch state {
        case .select:
            state = .idle
        case .drawing(let item):
            if !item.finishManually && item.canFinish {
                finishSession()
            }
        case .onRotator, .movingRotator:
            state = .idle
        case .onAnchor, .movingAnchor:
            state = .idle
        case .onPoint, .movingPoint:
            state = .idle
        case .onItem(let item, _):
            selectItems([item], byExtendingSelection: false)
            fallthrough
        case .movingItem:
            state = .idle
        default:
            break
        }
        
        refresh()
    }
    
    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
    }
    
    public override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        let location = convert(event.locationInWindow, from: nil)
        var menu: NSMenu?
        if let item = onItemTest(location) {
            menu = delegate?.canvasView?(self, menuFor: item)
        } else {
            menu = delegate?.menu?(for: self)
        }
        if let menu = menu {
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }
    }
    
    // MARK: -
    
    private func scale(x: CGFloat, y: CGFloat) {
        let allItems: [Shape] = {
            guard case .drawing(let item) = state else { return items }
            return items + [item]
        }()
        for item in allItems {
            item.scale(x: x, y: y)
        }
    }
    
    public func finishSession() {
        guard case .drawing(let item) = state else { return }
        let result = addItem(item)
        state = .idle
        if result {
            delegate?.canvasView?(self, didFinishSession: item)
        } else {
            delegate?.canvasViewDidCancelSession?(self)
        }
        refresh()
    }
    
    public func startSession(_ type: Shape.Type) {
        finishSession()
        deselectAllItems()
        let item = type.init()
        item.strokeColor = strokeColor
        item.fillColor = fillColor
        item.updateHandler = { [weak self] in self?.refresh() }
        state = .drawing(item)
    }
    
    // MARK: - Add / Remove
    
    @discardableResult
    public func addItem(_ item: Shape) -> Bool {
        guard item.canFinish else { return false }
        item.updateHandler = { [weak self] in self?.refresh() }
        item.markAsFinished()
        items.append(item)
        refresh()
        return true
    }
    
    public func removeItems(at indexes: IndexSet) {
        let deselecteds = indexes
            .sorted(by: >)
            .map { items.remove(at: $0) }
        
        refresh()
        
        if !deselecteds.isEmpty {
            delegate?.canvasView?(self, didDeselect: deselecteds.reversed())
        }
    }
    
    public func removeItems(_ itemsToRemove: [Shape]) {
        let indexes = IndexSet(itemsToRemove.compactMap(items.firstIndex(of:)))
        removeItems(at: indexes)
    }
    
    public func removeSelectedItems() {
        removeItems(selectedItems)
    }
    
    public func removeAllItems() {
        removeItems(items)
    }
    
    // MARK:: - Selection
    
    public func selectItems(at indexes: IndexSet, byExtendingSelection ext: Bool) {
        let curIndexes = Set(selectionIndexes)
        let newIndexes = ext ? curIndexes.union(indexes) : Set(indexes)
        let new = newIndexes.subtracting(curIndexes)
        let bye = curIndexes.subtracting(newIndexes)
        for (i, item) in items.enumerated() {
            item.isSelected = newIndexes.contains(i)
        }
        refresh()
        if !new.isEmpty {
            delegate?.canvasView?(self, didSelect: new.map({ items[$0] }))
        }
        if !bye.isEmpty {
            delegate?.canvasView?(self, didDeselect: bye.map({ items[$0] }))
        }
    }
    
    public func selectItems(_ itemsToSelect: [Shape], byExtendingSelection ext: Bool) {
        let indexes = IndexSet(itemsToSelect.compactMap(items.firstIndex(of:)))
        selectItems(at: indexes, byExtendingSelection: ext)
    }
    
    public func selectItems(with rect: CGRect) {
        let itemsToSelect = items.filter({ $0.selectTest(rect) })
        selectItems(itemsToSelect, byExtendingSelection: false)
    }
    
    public func selectAllItems() {
        selectItems(items, byExtendingSelection: false)
    }
    
    public func deselectItems(at indexes: IndexSet) {
        let indexes = selectionIndexes.subtracting(indexes)
        selectItems(at: indexes, byExtendingSelection: false)
    }
    
    public func deselectItems(_ itemsToDeselect: [Shape]) {
        let indexes = IndexSet(itemsToDeselect.compactMap(items.firstIndex(of:)))
        deselectItems(at: indexes)
    }
    
    public func deselectAllItems() {
        selectItems([], byExtendingSelection: false)
    }
    
}

// MARK: - Drawing Methods

extension CanvasView {
    
    private func drawSelector(with rect: CGRect, in ctx: CGContext) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        // Background
        ctx.setFillColor(selectorFillColor.cgColor)
        ctx.addRect(rect)
        ctx.fillPath()
        // Border
        ctx.setStrokeColor(selectorBorderColor.cgColor)
        ctx.addRect(rect)
        ctx.strokePath()
    }
    
    private func drawPoint(at point: CGPoint, pointStyle: PointStyle, rotationAngle: CGFloat, isHighlighted: Bool, in ctx: CGContext) {
        let len = selectionRange
        let borderColor: CGColor = .black
        let fillColor: CGColor = .white
        // Background
        pointStyle == .circle
            ? ctx.addCircle(Circle(center: point, radius: len))
            : ctx.addSquare(center: point, width: len, rotation: rotationAngle)
        ctx.setFillColor(isHighlighted ? highlightedColor.cgColor : fillColor)
        ctx.fillPath()
        // Border
        pointStyle == .circle
            ? ctx.addCircle(Circle(center: point, radius: len))
            : ctx.addSquare(center: point, width: len, rotation: rotationAngle)
        ctx.setStrokeColor(borderColor)
        ctx.strokePath()
    }
    
    private func drawPoints(for item: Shape, pointStyle: PointStyle, rotationAngle: CGFloat, highlightedIndexPath: IndexPath? = nil, in ctx: CGContext) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        item.layout.forEach { indexPath, point, _ in
            if isRotationEnabled, selectedItems.count == 1 {
                if case .indexPath(let anchorIndexPath) = item.rotationAnchor, anchorIndexPath == indexPath {
                    return
                }
            }
            let highlight = highlightedIndexPath == indexPath
            drawPoint(at: point, pointStyle: pointStyle, rotationAngle: rotationAngle, isHighlighted: highlight, in: ctx)
        }
    }
    
    private func drawAnchor(for item: Shape, pointStyle: PointStyle, rotationAngle: CGFloat, isHighlighted: Bool, in ctx: CGContext) {
        guard let center = item.rotationCenter else { return }
        
        ctx.saveGState()
        defer { ctx.restoreGState() }
        
        drawPoint(at: center, pointStyle: pointStyle, rotationAngle: rotationAngle, isHighlighted: isHighlighted, in: ctx)
        
        let len = selectionRange
        ctx.addCrosshair(center: center, length: len, angle: 0)
        ctx.setStrokeColor(.black)
        ctx.strokePath()
    }
    
    private func drawRotator(for item: Shape, isHighlighted: Bool, in ctx: CGContext) {
        guard let center = item.rotationCenter else { return }
        ctx.saveGState()
        defer { ctx.restoreGState() }
        let arc = Arc(center: center, radius: rotatorRadius,
                      from: item.rotationAngle - .pi / 4, to: item.rotationAngle + .pi / 4,
                      clockwise: false)
        let arrowLen: CGFloat = 6
        
        ctx.addArc(arc)
        ctx.setStrokeColor(isHighlighted ? highlightedColor.cgColor : .black)
        ctx.strokePath()
        ctx.addArrow(body: 0, head: arrowLen, angle: item.rotationAngle + .pi / 1.4,
                     at: center.extended(length: arc.radius, angle: arc.endAngle))
        ctx.setFillColor(isHighlighted ? highlightedColor.cgColor : .black)
        ctx.fillPath()
        ctx.addArrow(body: 0, head: arrowLen, angle: item.rotationAngle - .pi / 1.4,
                     at: center.extended(length: arc.radius, angle: arc.startAngle))
        ctx.fillPath()
    }
    
    private func drawAuxTool(for item: Shape, with indexPath: IndexPath, connected: Bool, in ctx: CGContext) {
        guard item[indexPath.section].count > 1 else { return }
        ctx.saveGState()
        defer { ctx.restoreGState() }
        let aIndexPath = IndexPath(item: indexPath.item + (indexPath.item == 0 ? 1 : -1),
                                   section: indexPath.section)
        let p1 = item[indexPath]
        let p2 = item[aIndexPath]
        let line = Line(from: p1, to: p2)
        let len = line.distance / 2
        let angle = line.angle
        if connected {
            ctx.addLine(line)
        }
        [p1, p2].forEach { point in
            ctx.addLines(between: [
                point.extended(length: len, angle: angle + .pi / 2),
                point.extended(length: len, angle: angle - .pi / 2),
            ])
        }
        ctx.setLineDash(phase: 2, lengths: [2, 2])
        ctx.strokePath()
    }
    
    private func drawMagnetPoint(at point: CGPoint, in ctx: CGContext) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        ctx.addCrosshair(center: point, length: 13, angle: 0)
        ctx.setLineWidth(2)
        ctx.setStrokeColor(highlightedColor.cgColor)
        ctx.strokePath()
    }
    
    private func drawMagnetPoints(for item: Shape, in ctx: CGContext) {
        for mItem in items.compactMap({ $0 as? Magnetizable }) {
            for magnet in mItem.magnets() where mItem != item {
                var point: CGPoint
                switch magnet {
                case .indexPath(let indexPath): point = mItem[indexPath]
                case .point(let p):             point = p
                }
                point = CGPoint(x: round(point.x), y: round(point.y))
                drawMagnetPoint(at: point, in: ctx)
            }
        }
    }
    
}

// MARK: - Selection Tests

extension CanvasView {
    
    private func onAnchorTest(_ location: CGPoint) -> Shape? {
        guard selectedItems.count == 1, let item = selectedItems.first, let center = item.rotationCenter else {
            return nil
        }
        return center.contains(location, in: selectionRange) ? item : nil
    }
    
    private func anchoringTest(item: Shape, location: CGPoint) -> Shape.Anchor {
        var anchor: Shape.Anchor?
        item.layout.forEach { (indexPath, point, stop) in
            guard point.contains(location, in: selectionRange) else { return }
            anchor = .indexPath(indexPath)
            stop = true
        }
        if anchor == nil {
            anchor = .point(location)
        }
        return anchor!
    }
    
    private func onRotatorTest(_ location: CGPoint) -> Shape? {
        guard selectedItems.count == 1, let item = selectedItems.first else { return nil }
        guard let center = item.rotationCenter else { return nil }
        let line = Line(from: center, to: location)
        let range = (rotatorRadius - selectionRange)...(rotatorRadius + selectionRange)
        guard range.contains(line.distance) else { return nil }
        let arc = Arc(center: center, radius: range.upperBound,
                      from: item.rotationAngle + .pi / 4, to: item.rotationAngle - .pi / 4,
                      clockwise: true)
        return arc.contains(location) ? item : nil
    }
    
    private func onPointTest(_ location: CGPoint) -> (Shape, IndexPath)? {
        for item in selectedItems {
            if let indexPath = item.hitTest(location, pointRange: selectionRange) {
                return (item, indexPath)
                
            }
        }
        return nil
    }
    
    private func onItemTest(_ location: CGPoint) -> Shape? {
        items.reversed().first { $0.hitTest(location, bodyRange: selectionRange) }
    }
    
    private func magnetTest(item: Shape, at location: CGPoint) -> (Shape, CGPoint)? {
        for mItem in items.compactMap({ $0 as? Magnetizable }) where mItem != item {
            guard let magnet = mItem.magnet(for: location, range: selectionRange) else { continue }
            let point: CGPoint
            switch magnet {
            case .indexPath(let indexPath): point = mItem[indexPath]
            case .point(let p):             point = p
            }
            return (mItem, point)
        }
        return nil
    }
    
}
