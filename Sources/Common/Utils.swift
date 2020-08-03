//
//  Tools.swift
//  Canvas
//
//  Created by scchn on 2020/7/22.
//  Copyright © 2020 scchn. All rights reserved.
//

import AppKit

public func radiansToDegrees(_ r: CGFloat) -> CGFloat { r / .pi * 180 }
public func degreesToRadians(_ d: CGFloat) -> CGFloat { d * .pi / 180 }

// MARK: -

public protocol Drawable {
    func draw(in ctx: CGContext)
}

public protocol CGPathProvider {
    var cgPath: CGPath { get }
}

extension Array where Element == CGPathProvider {
    func cgPath() -> CGPath {
        reduce(CGMutablePath()) { path, provider in
            path.addPath(provider.cgPath)
            return path
        }
    }
}

// MARK: - Magnetizable

public protocol Magnetizable: Shape {
    func magnets() -> [Shape.PointDescriptor]
    func magnet(for point: CGPoint, range: CGFloat) -> Shape.PointDescriptor?
}

extension Magnetizable {
    
    public func magnets() -> [Shape.PointDescriptor] {
        var magnets: [Shape.PointDescriptor] = []
        layout.forEach { (indexPath, _, _) in
            magnets += [.indexPath(item: indexPath.item, section: indexPath.section)]
        }
        return magnets
    }
    
    public func magnet(for location: CGPoint, range: CGFloat) -> Shape.PointDescriptor? {
        guard canFinish else { return nil }
        return magnets().first { magnet in
            let point: CGPoint = getPoint(with: magnet)
            return point.contains(location, in: range)
        }
    }
    
}
