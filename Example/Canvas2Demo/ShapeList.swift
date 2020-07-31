//
//  ShapeList.swift
//  Canvas2Demo
//
//  Created by scchn on 2020/7/31.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation
import Canvas2

extension CanvasView.PointStyle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .circle: return "Circle"
        case .square: return "Square"
        }
    }
}

enum ShapeList: Int, CaseIterable, CustomStringConvertible {
    
    case ruler
    case rect
    case polygon
    case circle
    case goniometer
    
    func convert() -> Shape.Type {
        switch self {
        case .ruler:        return RulerShape.self
        case .rect:         return RectangleShape.self
        case .circle:       return CircleShape.self
        case .polygon:      return PolygonShape.self
        case .goniometer:   return GoniometerShape.self
        }
    }
    
    var description: String {
        switch self {
        case .ruler:        return "Ruler"
        case .rect:         return "Rectangle"
        case .polygon:      return "Polygon"
        case .circle:       return "Circle"
        case .goniometer:   return "Goniometer"
        }
    }
    
}
