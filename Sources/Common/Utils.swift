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

public protocol Drawable: Codable {
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

public enum Magnet {
    case indexPath(IndexPath)
    case point(CGPoint)
}

public protocol Magnetizable: Shape {
    func magnets() -> [Magnet]
    func magnet(for point: CGPoint, range: CGFloat) -> Magnet?
}

extension Magnetizable {
    
    public func magnets() -> [Magnet] {
        var magnets: [Magnet] = []
        layout.forEach { (indexPath, _, _) in
            magnets += [.indexPath(indexPath)]
        }
        return magnets
    }
    
    public func magnet(for location: CGPoint, range: CGFloat) -> Magnet? {
        guard canFinish else { return nil }
        return magnets().first { magnet in
            let point: CGPoint
            switch magnet {
            case .indexPath(let indexPath): point = layout[indexPath]
            case .point(let p):             point = p
            }
            return point.contains(location, in: range)
        }
    }
    
}
