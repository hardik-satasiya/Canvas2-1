//
//  Polygon.swift
//  Canvas
//
//  Created by scchn on 2020/7/23.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation
import Canvas2

public final class PolygonShape: Shape, Magnetizable {
    
    public private(set) var lines: [Line] = []
    
    var isClosed: Bool = true {
        didSet { update() }
    }
    
    public override var canFinish: Bool {
        let cnt = layout.first?.count ?? 0
        return isClosed ? cnt > 2 : cnt > 1
    }
    
    public override func update() {
        super.update()
        if canFinish {
            let points = layout[0]
            let range = 0..<(points.endIndex - (isClosed ? 0 : 1))
            lines.removeAll()
            for i in range {
                let j = (i + 1) % points.count
                let line = Line(from: points[i], to: points[j])
                lines.append(line)
            }
        }
    }
    
    public override func updateBody() {
        guard isClosed && canFinish, let points = layout.first else {
            super.updateBody()
            return
        }
        
        body.removeAll()
        
        body.append(ShapePath(method: .stroke(1), color: strokeColor) { path in
            path.addLines(between: points)
            if isFinished {
                path.closeSubpath()
            }
        })
        
        if !isFinished, let indexPath = endIndexPath {
            let line = Line(from: layout[indexPath], to: layout[0][0])
            body.append(ShapePath(method: .defaultDash, color: strokeColor) { path in
                path.addLine(line)
            })
            body.append(ShapePath(method: .fill, color: fillColor, make: { path in
                path.addArrow(body: 0, head: 6, angle: line.angle, at: line.mid)
            }))
        }
    }
    
    public override func selectTest(_ rect: CGRect) -> Bool {
        lines.contains(where: rect.canSelect(_:))
    }
    
}
