//
//  Arc.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation

public struct Arc {
    
    public var center: CGPoint
    public var radius: CGFloat
    public var startAngle: CGFloat
    public var endAngle: CGFloat
    public var clockwise: Bool
    public var angle: CGFloat {
        let (aStart, aEnd) = transformed()
        return aStart > aEnd ? 2 * .pi - (aStart - aEnd) : aEnd - aStart
    }
    
    public init(center: CGPoint, radius: CGFloat, from startAngle: CGFloat, to endAngle: CGFloat, clockwise: Bool) {
        self.center = center
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.clockwise = clockwise
    }
    
    public static func vertex(_ vertex: CGPoint, point1: CGPoint, point2: CGPoint, radius: CGFloat) -> Arc {
        let line1 = Line(from: vertex, to: point1)
        let line2 = Line(from: vertex, to: point2)
        var arc = Arc(center: vertex, radius: radius,
                      from: line1.angle,
                      to: line2.angle, clockwise: true)
        if arc.angle > .pi {
            arc.clockwise = false
        }
        return arc
    }
    
    private func transformed() -> (CGFloat, CGFloat) {
        let pStart = center.extended(length: radius, angle: startAngle)
        let pEnd = center.extended(length: radius, angle: endAngle)
        let lStart = Line(from: center, to: pStart)
        let lEnd = Line(from: center, to: pEnd)
        return clockwise ? (lEnd.angle, lStart.angle) : (lStart.angle, lEnd.angle)
    }
    
    private func _contains(_ angle: CGFloat, reset: Bool) -> Bool {
        let aTarget = !reset ? angle : Line(from: center, to: center.extended(length: radius, angle: angle)).angle
        let (aStart, aEnd) = transformed()
        return (aStart < aEnd && (aStart...aEnd).contains(aTarget)) ||
            (aStart > aEnd && (aTarget > aStart || aTarget < aEnd))
    }
    
    public func contains(_ angle: CGFloat) -> Bool {
        return _contains(angle, reset: true)
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        guard center.contains(point, in: radius) else { return false }
        return _contains(Line(from: center, to: point).angle, reset: false)
    }
    
}
