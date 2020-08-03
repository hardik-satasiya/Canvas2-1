//
//  Shape.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import Cocoa

extension Shape {

    public enum PointDescriptor: Codable {
        case indexPath(item: Int, section: Int)
        case fixed(x: CGFloat, y: CGFloat)
        
        enum CodingKeys: String, CodingKey {
            case indexPath
            case fixed
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .indexPath(let item, let section):
                try container.encode(IndexPath(item: item, section: section), forKey: .indexPath)
            case .fixed(let x, let y):
                try container.encode(CGPoint(x: x, y: y), forKey: .fixed)
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
                self = .indexPath(item: indexPath.item, section: indexPath.section)
            case .fixed:
                let point = try container.decode(CGPoint.self, forKey: key)
                self = .fixed(x: point.x, y: point.y)
            }
        }
    }
    
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
    
}

open class Shape: NSObject, Codable {
    
    open var structure: [Drawable] = []
    open var body: [Drawable] = []
    open var bodyPath: CGPath? { body.compactMap { $0 as? CGPathProvider }.cgPath() }
    
    open private(set) var layout = Layout()
    open private(set) var rotationAngle: CGFloat = 0
    open private(set) var rotationAnchor: PointDescriptor = .indexPath(item: 0, section: 0)
    open var strokeColor: NSColor = .black {
        didSet { update() }
    }
    open var fillColor: NSColor = .black {
        didSet { update() }
    }
    open var lineWidth: CGFloat = 1 {
        didSet { update() }
    }
    
    open subscript(_ section: Int) -> [CGPoint] { layout[section] }
    open subscript(_ indexPath: IndexPath) -> CGPoint { layout[indexPath] }
    
    open var rotationCenter: CGPoint? {
        guard canFinish else { return nil }
        return getPoint(with: rotationAnchor)
    }
    
    open var endIndexPath: IndexPath? {
        guard !layout.points.isEmpty else { return nil }
        let lastSection = layout.points.count - 1
        return IndexPath(item: layout[lastSection].count - 1, section: lastSection)
    }
    
    // MARK: - Encoding / Decoding-related
    open private(set) var typeIdentifier: Int = -1
    private var decodeInfo: Data?
    
    // MARK: - Rules
    /// Default = -1.
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
    
    open func getPoint(with descriptor: PointDescriptor) -> CGPoint {
        switch descriptor {
        case let .indexPath(item, section): return self[IndexPath(item: item, section: section)]
        case let .fixed(x, y):              return CGPoint(x: x, y: y)
        }
    }
    
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
        if canFinish {
            updateBody()
        }
        updateHandler?()
    }
    
    /// Update your variables for later use in `updateStructure()` or `updateBody()` if needed.
    open func didUpdateLayout() {
        
    }
    
    open func push(_ point: CGPoint) {
        guard !isFinished else { return }
        layout.push(point)
        didUpdateLayout()
        update()
    }
    
    open func push(toNextSection point: CGPoint) {
        guard !isFinished else { return }
        layout.pushToNextSection(point)
        didUpdateLayout()
        update()
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
        update()
    }
    
    open func updateLast(_ point: CGPoint) {
        guard let indexPath = endIndexPath else { return }
        update(point, at: indexPath)
    }
    
    open func translate(_ offset: Offset) {
        guard canFinish else { return }
        if case .fixed(let x, let y) = rotationAnchor {
            rotationAnchor = .fixed(x: x + offset.x, y: y + offset.y)
        }
        for (i, points) in layout.enumerated() {
            for (j, point) in points.enumerated() {
                let indexPath = IndexPath(item: j, section: i)
                let newPoint = point.applying(.init(translationX: offset.x, y: offset.y))
                layout[indexPath] = newPoint
            }
        }
        didUpdateLayout()
        update()
    }
    
    open func scale(x sx: CGFloat, y sy: CGFloat) {
        if case .fixed(let x, let y) = rotationAnchor {
            anchor(at: .fixed(x: x * sx, y: y * sy))
        }
        layout.forEach { indexPath, point, _ in
            var newPoint = point
            newPoint.x *= sx
            newPoint.y *= sy
            layout[indexPath] = newPoint
        }
        didUpdateLayout()
        update()
    }
    
    open func anchor(at anchor: PointDescriptor) {
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
        update()
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
    
    public enum CodingKeys: String, CodingKey {
        case layout
        case rotationAngle
        case rotationAnchor
        case strokeColorData
        case fillColorData
        case lineWidth
        case typeIdentifier
        case decodeInfo
    }

    open func encode(to encoder: Encoder) throws {
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
        try container.encode(typeIdentifier, forKey: .typeIdentifier)
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
        rotationAnchor = try container.decode(PointDescriptor.self, forKey: .rotationAnchor)
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
        typeIdentifier = try container.decode(Int.self, forKey: .typeIdentifier)
        decodeInfo = try container.decodeIfPresent(Data.self, forKey: .decodeInfo)
        super.init()
        markAsFinished()
        didUpdateLayout()
        update()
    }
    
    open func applyDecodeInfo(_ data: Data) {
        
    }
    
    func convert(to type: Shape.Type) -> Shape {
        let shape = type.init()
        shape.layout = layout
        shape.rotationAngle = rotationAngle
        shape.rotationAnchor = rotationAnchor
        shape.strokeColor = strokeColor
        shape.fillColor = fillColor
        shape.lineWidth = lineWidth
        shape.isSelected = isSelected
        shape.isFinished = isFinished
        shape.didUpdateLayout()
        shape.update()
        if let decodeInfo = decodeInfo {
            shape.decodeInfo = decodeInfo
            shape.applyDecodeInfo(decodeInfo)
        }
        return shape
    }
    
}
