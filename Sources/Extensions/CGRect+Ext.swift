//
//  CGRect+Ext.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation

extension CGRect {
    
    private var corners: [CGPoint] {
        [
            CGPoint(x: minX, y: minY),
            CGPoint(x: maxX, y: minY),
            CGPoint(x: minX, y: maxY),
            CGPoint(x: maxX, y: maxY)
        ]
    }
    
    public func canSelect(_ rect: CGRect) -> Bool {
        intersects(rect) && !rect.contains(self)
    }
    
    public func canSelect(_ points: [CGPoint], isClosed: Bool) -> Bool {
        points.enumerated().contains { i, point in
            guard isClosed || i != points.count - 1 else { return false }
            let j = (i + 1) % points.count
            return canSelect(Line(from: point, to: points[j]))
        }
    }
    
    public func canSelect(_ line: Line) -> Bool {
        let line1 = Line(from: CGPoint(x: minX, y: minY), to: CGPoint(x: minX, y: maxY))
        let line2 = Line(from: CGPoint(x: maxX, y: minY), to: CGPoint(x: maxX, y: maxY))
        let line3 = Line(from: CGPoint(x: minX, y: minY), to: CGPoint(x: maxX, y: minY))
        let line4 = Line(from: CGPoint(x: minX, y: maxY), to: CGPoint(x: maxX, y: maxY))
        return contains(line.from)
            || contains(line.to)
            || line.collides(with: line1)
            || line.collides(with: line2)
            || line.collides(with: line3)
            || line.collides(with: line4)
    }
    
    public func canSelect(_ circle: Circle) -> Bool {
        let corners = [CGPoint(x: minX, y: minY), CGPoint(x: maxX, y: minY), CGPoint(x: minX, y: maxY), CGPoint(x: maxX, y: maxY)]
        guard corners.contains(where: { !circle.contains($0) }) else { return false }
        let x = circle.center.x < minX ? minX : (circle.center.x > maxX ? maxX : circle.center.x)
        let y = circle.center.y < minY ? minY : (circle.center.y > maxY ? maxY : circle.center.y)
        let dx = circle.center.x - x
        let dy = circle.center.y - y
        return dx * dx + dy * dy <= circle.radius * circle.radius
    }
    
    public func canSelect(_ arc: Arc) -> Bool {
        let ccount = corners.filter(arc.contains(_:)).count
        guard ccount == 0 else { return ccount != corners.count }
        let angles: [CGFloat] = [0, .pi / 2, .pi, -.pi / 2]
        for angle in angles.filter(arc.contains(_:)) {
            if contains(arc.center.extended(length: arc.radius, angle: angle)) {
                return true
            }
        }
        let lines = [
            Line(from: arc.center, to: arc.center.extended(length: arc.radius, angle: arc.startAngle)),
            Line(from: arc.center, to: arc.center.extended(length: arc.radius, angle: arc.endAngle))
        ]
        
        return lines.contains(where: canSelect(_:))
    }
    
}
