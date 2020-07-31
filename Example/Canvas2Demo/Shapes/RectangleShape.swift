//
//  Rectangle.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation
import Canvas2

/*
 0---1---2
 6       3
 5---4---7
 */

public final class RectangleShape: Shape, Magnetizable {
    
    private var order: [Int] = [0, 1, 2, 3, 7, 4, 5, 6]
    private var controlPoints: [CGPoint] { !canFinish ? [] : order.map { layout[0][$0] } }
    
    public override var supportsAuxTool: Bool { false }
    public override var canFinish: Bool { layout.points.first?.count == order.count }
    public override var finishManually: Bool { false }
    
    public init(rect: CGRect) {
        super.init()
        push(rect.origin)
        push(CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height))
    }
    
    public required init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public override func push(_ point: CGPoint) {
        guard let firstSection = layout.first else {
            super.push(point)
            return
        }
        guard firstSection.count == 1, let origin = firstSection.first else {
            return
        }
        let offset = Line(from: origin, to: point).offset
        super.push(origin.applying(.init(translationX: offset.x / 2, y: 0)))
        super.push(origin.applying(.init(translationX: offset.x, y: 0)))
        super.push(origin.applying(.init(translationX: offset.x, y: offset.y / 2)))
        super.push(origin.applying(.init(translationX: offset.x / 2, y: offset.y)))
        super.push(origin.applying(.init(translationX: 0, y: offset.y)))
        super.push(origin.applying(.init(translationX: 0, y: offset.y / 2)))
        super.push(point)
    }
    
    public override func updateStructure() {
        structure = []
    }
    
    public override func updateBody() {
        guard canFinish else {
            body = []
            return
        }
        body = [
            ShapePath(method: .stroke(lineWidth), color: strokeColor, make: { path in
                path.addLines(between: controlPoints)
                path.closeSubpath()
            })
        ]
    }
    
    public override func selectTest(_ rect: CGRect) -> Bool {
        guard canFinish else { return false }
        return rect.canSelect(controlPoints, isClosed: true)
    }

    public override func pointRelations() -> [IndexPath : [PointRelation]] {
        [
            IndexPath(item: order[0], section: 0): [
                .init(indexPath: IndexPath(item: order[7], section: 0), x: 1, y: 0.5),
                .init(indexPath: IndexPath(item: order[6], section: 0), x: 1, y: 0),
                .init(indexPath: IndexPath(item: order[5], section: 0), x: 0.5, y: 0),
                .init(indexPath: IndexPath(item: order[1], section: 0), x: 0.5, y: 1),
                .init(indexPath: IndexPath(item: order[2], section: 0), x: 0, y: 1),
                .init(indexPath: IndexPath(item: order[3], section: 0), x: 0, y: 0.5),
            ],
            IndexPath(item: order[2], section: 0): [
                .init(indexPath: IndexPath(item: order[1], section: 0), x: 0.5, y: 1),
                .init(indexPath: IndexPath(item: order[0], section: 0), x: 0, y: 1),
                .init(indexPath: IndexPath(item: order[7], section: 0), x: 0, y: 0.5),
                .init(indexPath: IndexPath(item: order[3], section: 0), x: 1, y: 0.5),
                .init(indexPath: IndexPath(item: order[4], section: 0), x: 1, y: 0),
                .init(indexPath: IndexPath(item: order[5], section: 0), x: 0.5, y: 0),
            ],
            IndexPath(item: order[4], section: 0): [
                .init(indexPath: IndexPath(item: order[3], section: 0), x: 1, y: 0.5),
                .init(indexPath: IndexPath(item: order[2], section: 0), x: 1, y: 0),
                .init(indexPath: IndexPath(item: order[1], section: 0), x: 0.5, y: 0),
                .init(indexPath: IndexPath(item: order[5], section: 0), x: 0.5, y: 1),
                .init(indexPath: IndexPath(item: order[6], section: 0), x: 0, y: 1),
                .init(indexPath: IndexPath(item: order[7], section: 0), x: 0, y: 0.5),
            ],
            IndexPath(item: order[6], section: 0): [
                .init(indexPath: IndexPath(item: order[5], section: 0), x: 0.5, y: 1),
                .init(indexPath: IndexPath(item: order[4], section: 0), x: 0, y: 1),
                .init(indexPath: IndexPath(item: order[3], section: 0), x: 0, y: 0.5),
                .init(indexPath: IndexPath(item: order[7], section: 0), x: 1, y: 0.5),
                .init(indexPath: IndexPath(item: order[0], section: 0), x: 1, y: 0),
                .init(indexPath: IndexPath(item: order[1], section: 0), x: 0.5, y: 0),
            ],
            IndexPath(item: order[7], section: 0): [
                .init(indexPath: IndexPath(item: order[7], section: 0), x: 0, y: -1),
                .init(indexPath: IndexPath(item: order[0], section: 0), x: 1, y: 0),
                .init(indexPath: IndexPath(item: order[1], section: 0), x: 0.5, y: 0),
                .init(indexPath: IndexPath(item: order[6], section: 0), x: 1, y: 0),
                .init(indexPath: IndexPath(item: order[5], section: 0), x: 0.5, y: 0),
            ],
            IndexPath(item: order[3], section: 0): [
                .init(indexPath: IndexPath(item: order[3], section: 0), x: 0, y: -1),
                .init(indexPath: IndexPath(item: order[2], section: 0), x: 1, y: 0),
                .init(indexPath: IndexPath(item: order[1], section: 0), x: 0.5, y: 0),
                .init(indexPath: IndexPath(item: order[4], section: 0), x: 1, y: 0),
                .init(indexPath: IndexPath(item: order[5], section: 0), x: 0.5, y: 0),
            ],
            IndexPath(item: order[1], section: 0): [
                .init(indexPath: IndexPath(item: order[1], section: 0), x: -1, y: 0),
                .init(indexPath: IndexPath(item: order[0], section: 0), x: 0, y: 1),
                .init(indexPath: IndexPath(item: order[7], section: 0), x: 0, y: 0.5),
                .init(indexPath: IndexPath(item: order[2], section: 0), x: 0, y: 1),
                .init(indexPath: IndexPath(item: order[3], section: 0), x: 0, y: 0.5),
            ],
            IndexPath(item: order[5], section: 0): [
                .init(indexPath: IndexPath(item: order[5], section: 0), x: -1, y: 0),
                .init(indexPath: IndexPath(item: order[4], section: 0), x: 0, y: 1),
                .init(indexPath: IndexPath(item: order[3], section: 0), x: 0, y: 0.5),
                .init(indexPath: IndexPath(item: order[6], section: 0), x: 0, y: 1),
                .init(indexPath: IndexPath(item: order[7], section: 0), x: 0, y: 0.5),
            ],
        ]
    }
    
}
