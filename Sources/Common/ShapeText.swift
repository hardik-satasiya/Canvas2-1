//
//  ShapeText.swift
//  Canvas2
//
//  Created by scchn on 2020/7/31.
//

import AppKit

public class ShapeText: Drawable, Codable {
    
    public var string: NSAttributedString
    public var point: CGPoint
    public var angle: CGFloat
    
    public init(string: NSAttributedString, at point: CGPoint, rotation: CGFloat = 0) {
        self.string = string
        self.point = point
        self.angle = rotation
    }
    
    public init(text: String,
                color: NSColor = .black,
                font: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize),
                at point: CGPoint,
                rotation: CGFloat = 0)
    {
        self.string = NSAttributedString(string: text, attributes: [.foregroundColor: color, .font: font])
        self.point = point
        self.angle = rotation
    }
    
    public func draw(in ctx: CGContext) {
        defer { ctx.restoreGState() }
        ctx.saveGState()
        CGContext.push(ctx) { _ in
            ctx.translateBy(x: point.x, y: point.y)
            ctx.rotate(by: angle)
            string.draw(at: .zero)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case stringData
        case point
        case angle
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let stringData = NSKeyedArchiver.archivedData(withRootObject: string)
        try container.encode(stringData, forKey: .stringData)
        try container.encode(point, forKey: .point)
        try container.encode(angle, forKey: .angle)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let stringData = try container.decode(Data.self, forKey: .stringData)
        guard let string = NSKeyedUnarchiver.unarchiveObject(with: stringData) as? NSAttributedString else {
            throw DecodingError.dataCorruptedError(forKey: .stringData, in: container,
                                                   debugDescription: "Unabled to decode `string`.")
        }
        self.string = string
        point = try container.decode(CGPoint.self, forKey: .point)
        angle = try container.decode(CGFloat.self, forKey: .angle)
    }
    
}
