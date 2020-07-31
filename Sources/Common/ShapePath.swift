//
//  ShapePath.swift
//  Canvas2
//
//  Created by scchn on 2020/7/31.
//

import AppKit

public class ShapePath: Drawable, CGPathProvider {
    public enum Method: Equatable {
        case stroke(CGFloat)
        case dash(CGFloat, CGFloat, [CGFloat])
        case fill
        
        public static let defaultDash = Method.dash(1, 2, [2, 2])
    }
    
    public var cgPath: CGPath
    public var color: NSColor
    public var method: Method
    
    public init(path: CGPath, method: Method, color: NSColor) {
        self.cgPath = path
        self.method = method
        self.color = color
    }
    
    public init(method: Method, color: NSColor, make: (CGMutablePath) -> Void) {
        let mPath = CGMutablePath()
        self.cgPath = mPath
        self.method = method
        self.color = color
        make(mPath)
    }
    
    public func draw(in ctx: CGContext) {
        defer { ctx.restoreGState() }
        ctx.saveGState()
        
        ctx.addPath(cgPath)
        
        switch method {
        case .dash(let w, let p, let ls):
            ctx.setLineDash(phase: p, lengths: ls); fallthrough
        case .stroke(let w):
            ctx.setLineWidth(w)
            ctx.setStrokeColor(color.cgColor)
            ctx.strokePath()
        default:
            ctx.setFillColor(color.cgColor)
            ctx.fillPath()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case pathElements
        case colorData
        case method
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(method, forKey: .method)
        let colorData = NSKeyedArchiver.archivedData(withRootObject: color)
            // NSArchiver.archivedData(withRootObject: color)
        try container.encode(colorData, forKey: .colorData)
        try container.encode(cgPath.elements(), forKey: .pathElements)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cgPath = CGPath.from(elements: try container.decode([CGPath.Element].self, forKey: .pathElements))
        let colorData = try container.decode(Data.self, forKey: .colorData)
        guard let color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? NSColor else {
            throw DecodingError.dataCorruptedError(forKey: .colorData, in: container,
                                                   debugDescription: "Unabled to decode `color`.")
        }
        self.color = color
        method = try container.decode(Method.self, forKey: .method)
    }
    
}

extension ShapePath.Method: Codable {
    
    enum CodingKeys: String, CodingKey {
        case stroke
        case dash
        case fill
    }
    
    enum DashCodingKeys: String, CodingKey {
        case lineWidth
        case phase
        case lengths
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .stroke(let w):
            try container.encode(w, forKey: .stroke)
        case .dash(let w, let p, let l):
            var nContainer = container.nestedContainer(keyedBy: DashCodingKeys.self, forKey: .dash)
            try nContainer.encode(w, forKey: .lineWidth)
            try nContainer.encode(p, forKey: .phase)
            try nContainer.encode(l, forKey: .lengths)
        case .fill:
            try container.encode(true, forKey: .fill)
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
        case .stroke:
            let w = try container.decode(CGFloat.self, forKey: key)
            self = .stroke(w)
        case .dash:
            let nContainer = try container.nestedContainer(keyedBy: DashCodingKeys.self, forKey: key)
            let w = try nContainer.decode(CGFloat.self, forKey: .lineWidth)
            let p = try nContainer.decode(CGFloat.self, forKey: .phase)
            let l = try nContainer.decode([CGFloat].self, forKey: .lengths)
            self = .dash(w, p, l)
        case .fill:
            self = .fill
        }
    }
    
}
