//
//  Line.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation

public typealias Offset = CGPoint

public struct Line {
    
    public var from: CGPoint
    public var to: CGPoint
    public var dx: CGFloat { to.x  -  from.x }
    public var dy: CGFloat { to.y  -  from.y }
    public var offset: Offset { CGPoint(x: dx, y: dy) }
    public var distance: CGFloat { sqrt(dx * dx + dy * dy) }
    public var angle: CGFloat { atan2(dy, dx) }
    public var mid: CGPoint { CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2) }
    
    public init(from: CGPoint, to: CGPoint) {
        self.from = from
        self.to = to
    }
    
    public func collides(with line: Line) -> Bool {
        let uA = (line.dx * (from.y - line.from.y) - line.dy * (from.x - line.from.x)) /
        (line.dy * dx - line.dx * dy)
        let uB = (dx * (from.y - line.from.y) - dy * (from.x - line.from.x)) /
        (line.dy * dx - line.dx * dy)
        return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1
    }
    
}
