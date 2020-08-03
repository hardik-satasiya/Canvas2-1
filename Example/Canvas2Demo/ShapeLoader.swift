//
//  ShapeLoader.swift
//  Canvas2Demo
//
//  Created by scchn on 2020/8/5.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation
import Canvas2

class ShapeLoader {
    
    private let key = "Shapes"
    
    private(set) var shapes: [Shape] = []
    
    func load() throws -> [Shape] {
        guard let data = UserDefaults.standard.value(forKey: "Shapes") as? Data else { return [] }
        let decoder = ShapeDecoder<ShapeList>()
        let shapes = try decoder.decode([Shape].self, from: data)
        self.shapes = shapes.compactMap(decoder.convert(_:))
        return self.shapes
    }
    
    func save(_ shapes: [Shape]) throws {
        let data = try ShapeEncoder().encode(shapes)
        UserDefaults.standard.setValue(data, forKey: "Shapes")
    }
    
}
