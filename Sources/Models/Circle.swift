//
//  Circle.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation

public struct Circle {
    
    public var center: CGPoint
    public var radius: CGFloat
    
    public init(center: CGPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }
    
    public init?(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) {
        guard let (center, radius) = genCircle(p1, p2, p3) else { return nil }
        self.center = center
        self.radius = radius
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        center.contains(point, in: radius)
    }
    
}

// MARK: - 3-Point Circle

fileprivate func calcA(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
    return (p1.x * (p2.y - p3.y) - p1.y * (p2.x - p3.x) + p2.x * p3.y - p3.x * p2.y)
}

fileprivate func calcB(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat{
    let a = (p1.x * p1.x + p1.y * p1.y) * (p3.y - p2.y)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p1.y - p3.y)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p2.y - p1.y)
    return a + b + c
}

fileprivate func calcC(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat{
    let a = (p1.x * p1.x + p1.y * p1.y) * (p2.x - p3.x)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p3.x - p1.x)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p1.x - p2.x)
    return a + b + c
}

fileprivate func calcD(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
    let a = (p1.x * p1.x + p1.y * p1.y) * (p3.x * p2.y - p2.x * p3.y)
    let b = (p2.x * p2.x + p2.y * p2.y) * (p1.x * p3.y - p3.x * p1.y)
    let c = (p3.x * p3.x + p3.y * p3.y) * (p2.x * p1.y - p1.x * p2.y)
    return a + b + c
}

public func genCircle(_ point1: CGPoint, _ point2: CGPoint, _ point3: CGPoint) -> (center: CGPoint, radius: CGFloat)? {
    let a = calcA(point1, point2, point3)
    let b = calcB(point1, point2, point3)
    let c = calcC(point1, point2, point3)
    let d = calcD(point1, point2, point3)
    let center = CGPoint(x: -b / (2 * a), y: -c / (2 * a))
    let radius = sqrt((b * b + c * c - (4 * a * d)) / (4 * a * a))
    
    guard (!center.x.isNaN && !center.x.isInfinite) &&
            (!center.y.isNaN && !center.y.isInfinite) &&
            (!radius.isNaN && !radius.isInfinite) else
    {
        return nil
    }

    return (center, radius)
}
