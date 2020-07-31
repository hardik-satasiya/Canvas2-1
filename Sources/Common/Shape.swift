//
//  Shape.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import Cocoa

extension Shape: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let item = type(of: self).init()
        item.layout = layout
        item.rotationAngle = rotationAngle
        item.rotationAnchor = rotationAnchor
        item.strokeColor = strokeColor
        item.fillColor = fillColor
        item.lineWidth = lineWidth
        item.isSelected = isSelected
        item.isFinished = isFinished
        item.update()
        return item
    }
}

extension Shape {
    
    public struct PointRelation {
        public var indexPath: IndexPath
        public var x: CGFloat
        public var y: CGFloat
        
        public init(indexPath: IndexPath, x: CGFloat, y: CGFloat) {
            self.indexPath = indexPath
            self.x = x
            self.y = y
        }
    }
    
    public enum Anchor: Codable {
        case indexPath(IndexPath)
        case point(CGPoint)
        
        enum CodingKeys: String, CodingKey {
            case indexPath
            case point
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .indexPath(let indexPath):
                try container.encode(indexPath, forKey: .indexPath)
            case .point(let point):
                try container.encode(point, forKey: .point)
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard let key = container.allKeys.first else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: container.codingPath,
                                          debugDescription: "Unabled to decode \(type(of: self)).")
                )
            }
            switch key {
            case .indexPath:
                let indexPath = try container.decode(IndexPath.self, forKey: key)
                self = .indexPath(indexPath)
            case .point:
                let point = try container.decode(CGPoint.self, forKey: key)
                self = .point(point)
            }
        }
    }
    
}

open class Shape: NSObject, Codable {
    
    open var structure: [Drawable] = []
    open var body: [Drawable] = []
    open var bodyPath: CGPath? { body.compactMap { $0 as? CGPathProvider }.cgPath() }
    
    open private(set) var layout = Layout()
    open private(set) var rotationAngle: CGFloat = 0
    open private(set) var rotationAnchor: Anchor = .indexPath(IndexPath(item: 0, section: 0))
    open var strokeColor: NSColor = .black {
        didSet { update() }
    }
    open var fillColor: NSColor = .black {
        didSet { update() }
    }
    open var lineWidth: CGFloat = 1 {
        didSet { update() }
    }
    
    open var rotationCenter: CGPoint? {
        guard canFinish else { return nil }
        switch rotationAnchor {
        case .indexPath(let indexPath): return layout[indexPath]
        case .point(let point): return point
        }
    }
    
    open var endIndexPath: IndexPath? {
        guard !layout.points.isEmpty else { return nil }
        let lastSection = layout.points.count - 1
        return IndexPath(item: layout[lastSection].count - 1, section: lastSection)
    }
    
    // MARK: - Rules
    open var supportsAuxTool: Bool { true }
    open internal(set) var isSelected: Bool = false
    open var canFinish: Bool { true }
    open var finishManually: Bool { true }
    open private(set) var isFinished: Bool = false
    var updateHandler: (() -> Void)?
    
    // MARK: -
    
    public required override init() {
        super.init()
    }
    
    // MARK: - Main Methods
    
    open func pointRelations() -> [IndexPath: [PointRelation]] { [:] }
    
    open func updateStructure() {
        structure = layout.reduce([Drawable]()) { lines, points in
            let path = ShapePath(method: .dash(lineWidth, 2, [2, 2]), color: strokeColor) {
                $0.addLines(between: points)
            }
            return lines + [path]
        }
    }
    
    open func updateBody() {
        body = layout.reduce([Drawable]()) { lines, points in
            let path = ShapePath(method: .stroke(lineWidth), color: strokeColor) {
                $0.addLines(between: points)
            }
            return lines + [path]
        }
    }
    
    open func update() {
        updateStructure()
        updateBody()
        updateHandler?()
    }
    
    /// Must call `super`.
    open func didUpdateLayout() {
        update()
    }
    
    open func push(_ point: CGPoint) {
        guard !isFinished else { return }
        layout.push(point)
        didUpdateLayout()
    }
    
    open func update(_ point: CGPoint, at indexPath: IndexPath) {
        let oldPoint = layout[indexPath]
        layout[indexPath] = point
        if let rotationCenter = rotationCenter {
            let offset = Line(from: oldPoint.rotated(origin: rotationCenter, angle: -rotationAngle),
                              to: point.rotated(origin: rotationCenter, angle: -rotationAngle)).offset
            
            if canFinish, let relations = pointRelations()[indexPath] {
                for relation in relations {
                    let point = layout[relation.indexPath]
                        .rotated(origin: rotationCenter, angle: -rotationAngle)
                        .applying(.init(translationX: relation.x * offset.x, y: relation.y * offset.y))
                        .rotated(origin: rotationCenter, angle: rotationAngle)
                    layout[relation.indexPath] = point
                }
            }
        }
        didUpdateLayout()
    }
    
    open func updateLast(_ point: CGPoint) {
        guard let indexPath = endIndexPath else { return }
        update(point, at: indexPath)
    }
    
    open func translate(_ offset: Offset) {
        guard canFinish else { return }
        if case .point(let point) = rotationAnchor {
            rotationAnchor = .point(CGPoint(x: point.x + offset.x, y: point.y + offset.y))
        }
        for (i, points) in layout.enumerated() {
            for (j, point) in points.enumerated() {
                let indexPath = IndexPath(item: j, section: i)
                let newPoint = point.applying(.init(translationX: offset.x, y: offset.y))
                layout[indexPath] = newPoint
            }
        }
        didUpdateLayout()
    }
    
    open func scale(x: CGFloat, y: CGFloat) {
        if case .point(let center) = rotationAnchor {
            anchor(at: Anchor.point(CGPoint(x: center.x * x, y: center.y * y)))
        }
        layout.forEach { indexPath, point, _ in
            var newPoint = point
            newPoint.x *= x
            newPoint.y *= x
            layout[indexPath] = newPoint
        }
        didUpdateLayout()
    }
    
    open func anchor(at anchor: Anchor) {
        guard canFinish else { return }
        rotationAnchor = anchor
    }
    
    open func rotate(_ angle: CGFloat) {
        guard let rotationCenter = rotationCenter else { return }
        for (i, points) in layout.enumerated() {
            for (j, point) in points.enumerated() {
                let indexPath = IndexPath(item: j, section: i)
                let newPoint = point.rotated(origin: rotationCenter, angle: angle - rotationAngle)
                layout[indexPath] = newPoint
            }
        }
        rotationAngle = angle
        didUpdateLayout()
    }
    
    open func markAsFinished() {
        guard canFinish else { return }
        isFinished = true
        update()
    }
    
    // MARK: - Drawing
    
    open func draw(with rect: CGRect, in ctx: CGContext) {
        if !isFinished {
            structure.forEach { $0.draw(in: ctx) }
        }
        body.forEach { $0.draw(in: ctx) }
    }
    
    // MARK: - Selection
    
    open func hitTest(_ location: CGPoint, pointRange: CGFloat) -> IndexPath? {
        var result: IndexPath?
        layout.forEach { indexPath, point, stop in
            guard point.contains(location, in: pointRange) else { return }
            result = indexPath
            stop = true
        }
        return result
    }
    
    open func hitTest(_ location: CGPoint, bodyRange: CGFloat) -> Bool {
        guard let path = bodyPath else { return false }
        let sPath = path.copy(strokingWithWidth: bodyRange * 2,
                              lineCap: .round,
                              lineJoin: .round,
                              miterLimit: 0)
        return sPath.contains(location)
    }
    
    open func selectTest(_ rect: CGRect) -> Bool {
        layout.contains { points in rect.canSelect(points, isClosed: false) }
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case layout
        case rotationAngle
        case rotationAnchor
        case strokeColorData
        case fillColorData
        case lineWidth
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        guard isFinished else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath,
                                      debugDescription: "Must be finised.")
            )
        }
        let strokeColorData = NSKeyedArchiver.archivedData(withRootObject: strokeColor)
        let fillColorData = NSKeyedArchiver.archivedData(withRootObject: fillColor)
        try container.encode(layout, forKey: .layout)
        try container.encode(rotationAngle, forKey: .rotationAngle)
        try container.encode(rotationAnchor, forKey: .rotationAnchor)
        try container.encode(strokeColorData, forKey: .strokeColorData)
        try container.encode(fillColorData, forKey: .fillColorData)
        try container.encode(lineWidth, forKey: .lineWidth)
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let strokeColorData = try container.decode(Data.self, forKey: .strokeColorData)
        let fillColorData = try container.decode(Data.self, forKey: .fillColorData)
        guard let strokeColor = NSKeyedUnarchiver.unarchiveObject(with: strokeColorData) as? NSColor else {
            throw DecodingError.dataCorruptedError(forKey: .strokeColorData, in: container,
                                                   debugDescription: "Unabled to decode `strokeColor`.")
        }
        guard let fillColor = NSKeyedUnarchiver.unarchiveObject(with: fillColorData) as? NSColor else {
            throw DecodingError.dataCorruptedError(forKey: .strokeColorData, in: container,
                                                   debugDescription: "Unabled to decode `fillColor`.")
        }
        layout = try container.decode(Layout.self, forKey: .layout)
        rotationAngle = try container.decode(CGFloat.self, forKey: .rotationAngle)
        rotationAnchor = try container.decode(Anchor.self, forKey: .rotationAnchor)
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
        super.init()
        markAsFinished()
        didUpdateLayout()
    }
    
}
