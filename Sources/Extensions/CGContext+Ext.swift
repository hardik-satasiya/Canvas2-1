//
//  CGContext+Ext.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import AppKit

extension CGContext {
    
    public func addLine(_ line: Line) {
        addLines(between: [line.from, line.to])
    }
    
    public func addCircle(_ circle: Circle) {
        addArc(center: circle.center, radius: circle.radius,
               startAngle: 0, endAngle: .pi * 2,
               clockwise: true)
    }
    
    public func addArc(_ arc: Arc) {
        addArc(center: arc.center, radius: arc.radius,
               startAngle: arc.startAngle, endAngle: arc.endAngle,
               clockwise: arc.clockwise)
    }
    
    public func addSquare(center: CGPoint, width: CGFloat, rotation: CGFloat = 0) {
        let s: CGFloat = .pi / 4
        let d = width * sqrt(2)
        let points = (0..<4).reduce([CGPoint]()) { points, i in
            let p = center
                .extended(length: d, angle: s + rotation + CGFloat(i) * .pi / 2)
            return points + [p]
        }
        addLines(between: points)
        closePath()
    }
    
    public func addCrosshair(center: CGPoint, length: CGFloat, angle: CGFloat) {
        addLines(between: [
            center.extended(length: length / 2, angle: .pi * 0.5 + angle),
            center.extended(length: length / 2, angle: .pi * 1.5 - angle),
        ])
        addLines(between: [
            center.extended(length: length / 2, angle: angle),
            center.extended(length: length / 2, angle: .pi + angle),
        ])
    }
    
    public func addArrow(body: CGFloat, head: CGFloat, angle: CGFloat, at origin: CGPoint) {
        let dst = origin.extended(length: body, angle: angle)
        addLines(between: [origin, dst])
        addLines(between: [
            dst.extended(length: head, angle: angle + .pi - .pi / 4),
            dst,
            dst.extended(length: head, angle: angle + .pi + .pi / 4)
        ])
    }
    
    public func addRotator(center: CGPoint, radius: CGFloat, angle: CGFloat) {
        let start = angle - .pi / 4
        let end = angle + .pi / 4
        let arrowLen: CGFloat = 6
        addArc(center: center, radius: radius,
               startAngle: start, endAngle: end,
               clockwise: false)
        addArrow(body: 0, head: arrowLen, angle: angle + .pi / 1.4,
                 at: center.extended(length: radius, angle: end))
    }
    
    public static func push(_ ctx: CGContext, _ block: (CGContext) -> Void) {
        let curr = NSGraphicsContext.current
        defer { NSGraphicsContext.current = curr }
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        block(ctx)
    }
    
}
