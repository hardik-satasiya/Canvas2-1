//
//  CGPath+Ext.swift
//  Canvas
//
//  Created by scchn on 2020/7/23.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation

extension CGMutablePath {
    
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
    
    public func addCrosshair(center: CGPoint, length: CGFloat, angle: CGFloat) {
        addLines(between: [
            center.extended(length: length / 2, angle: .pi * 0.5 + angle),
            center.extended(length: length / 2, angle: .pi * 1.5 + angle),
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
    
}

extension CGPath {
    
    struct Element: Codable, Equatable {
        enum ElementType: Int, Codable, Equatable {
            case moveToPoint
            case addLineToPoint
            case addCurveToPoint
            case addQuadCurveToPoint
            case close
        }
        var type: ElementType
        var points: [CGPoint]
    }
    
    func forEach( body: @escaping @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void =
            { (info, element) in
                let body = unsafeBitCast(info, to: Body.self)
                body(element.pointee)
            }
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }
    
    func elements() -> [Element] {
        var elements: [Element] = []
        forEach { element in
            switch element.type {
            case .moveToPoint:
                elements.append(Element(type: .moveToPoint, points: [element.points[0]]))
            case .addLineToPoint:
                let points = [element.points[0]]
                elements.append(Element(type: .addLineToPoint, points: points))
            case .addQuadCurveToPoint:
                let points = [element.points[0], element.points[1]]
                elements.append(Element(type: .addQuadCurveToPoint, points: points))
            case .addCurveToPoint:
                let points = [element.points[0], element.points[1], element.points[2]]
                elements.append(Element(type: .addCurveToPoint, points: points))
            case .closeSubpath:
                elements.append(Element(type: .close, points: []))
            @unknown default:
                break
            }
        }
        return elements
    }

    static func from(elements: [Element]) -> CGPath {
        let path = CGMutablePath()
        
        for element in elements {
            switch element.type {
            case .moveToPoint:
                path.move(to: element.points[0])
            case .addLineToPoint:
                path.addLine(to: element.points[0])
            case .addQuadCurveToPoint:
                let currentPoint = path.currentPoint
                let x = (currentPoint.x + 2 * element.points[0].x) / 3
                let y = (currentPoint.y + 2 * element.points[0].y) / 3
                let interpolatedPoint = CGPoint(x: x, y: y)
                let endPoint = element.points[1]
                path.addCurve(to: endPoint, control1: interpolatedPoint, control2: interpolatedPoint)
            case .addCurveToPoint:
                path.addCurve(to: element.points[2], control1: element.points[0], control2: element.points[1])
            case .close:
                path.closeSubpath()
            }
        }
        return path
    }
    
}
