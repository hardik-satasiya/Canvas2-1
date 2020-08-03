//
//  ShapeDecoder.swift
//  Canvas2
//
//  Created by scchn on 2020/8/5.
//

import Foundation

public protocol ShapeTypeConvertible {
    var rawValue: Int { get }
    init?(rawValue: Int)
    func shapeType() -> Shape.Type
}

public enum ShapeDecoderError: Error {
    case undefinedIdentifier
}

public class ShapeDecoder<T: ShapeTypeConvertible>: JSONDecoder {
    
    public func convert(_ shape: Shape) -> Shape? {
        guard let converter = T(rawValue: shape.typeIdentifier) else { return nil }
        return shape.convert(to: converter.shapeType())
    }
    
}
