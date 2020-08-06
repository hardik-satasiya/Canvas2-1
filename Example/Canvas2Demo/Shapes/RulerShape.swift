//
//  Ruler.swift
//  Canvas
//
//  Created by scchn on 2020/7/23.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation
import Canvas2

public final class RulerShape: Shape, Magnetizable {
    
    private var line: Line?
    
    public override var typeIdentifier: Int { 0 }
    public override var canFinish: Bool { layout.first?.count == 2 }
    public override var finishManually: Bool { false }
    
    public init(line: Line) {
        super.init()
        self.line = line
        push(line.from)
        push(line.to)
    }
    
    public required init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public override func push(_ point: CGPoint, toNextSection: Bool = false) {
        guard !canFinish else { return }
        super.push(point)
    }
    
    public override func didUpdateLayout() {
        super.didUpdateLayout()
        if canFinish {
            line = Line(from: layout[0][0], to: layout[0][1])
        }
    }
    
}
