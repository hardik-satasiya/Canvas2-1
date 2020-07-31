//
//  CGPoint+Ext.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation

extension CGPoint {
    
    public func extended(length: CGFloat, angle: CGFloat = 0) -> CGPoint {
        CGPoint(x: x + length * cos(angle), y: y + length * sin(angle))
    }
    
    public mutating func extend(length: CGFloat, angle: CGFloat = 0) {
        self = extended(length: length, angle: angle)
    }
    
    public func rotated(origin: CGPoint, angle: CGFloat) -> CGPoint {
        let transform = CGAffineTransform.identity.translatedBy(x: origin.x, y: origin.y).rotated(by: angle)
        return CGPoint(x: x - origin.x, y: y - origin.y).applying(transform)
    }
    
    public mutating func rotate(origin: CGPoint, angle: CGFloat) {
        self = rotated(origin: origin, angle: angle)
    }
    
    public func contains(_ point: CGPoint, in radius: CGFloat) -> Bool {
        let dx = point.x - x
        let dy = point.y - y
        return dx * dx + dy * dy <= radius * radius
    }
    
}
