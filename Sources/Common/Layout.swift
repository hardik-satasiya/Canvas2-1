//
//  Stack.swift
//  Canvas
//
//  Created by scchn on 2020/7/20.
//  Copyright © 2020 scchn. All rights reserved.
//

import Foundation

public struct Layout: Codable, Sequence, IteratorProtocol {
    
    private var counter: Int = 0
    
    public typealias Element = [CGPoint]
    
    public mutating func next() -> [CGPoint]? {
        guard counter < points.count else { return nil }
        defer { counter += 1 }
        return points[counter]
    }
    
    public private(set) var points: [[CGPoint]] = []
    
    public var first: [CGPoint]? { points.first }
    public var last: [CGPoint]? { points.last }
    public var isEmpty: Bool { first == nil }
    
    public subscript(_ indexPath: IndexPath) -> CGPoint {
        get { points[indexPath.section][indexPath.item] }
        set { points[indexPath.section][indexPath.item] = newValue }
    }
    
    public subscript(_ i: Int, _ j: Int) -> CGPoint {
        get { points[i][j] }
        set { points[i][j] = newValue }
    }
    
    public subscript(_ i: Int) -> [CGPoint] {
        points[i]
    }
    
    public init() {
        
    }
    
    public mutating func push(_ point: CGPoint) {
        if points.isEmpty {
            points.append([point])
        } else {
            points[points.count - 1] += [point]
        }
    }
    
    public mutating func pushToNextSection(_ point: CGPoint) {
        if !points.isEmpty {
            points.append([point])
        } else {
            push(point)
        }
    }
    
    @discardableResult
    public mutating func pop() -> CGPoint? {
        guard !points.isEmpty else { return nil }
        let idx = points.index(before: points.endIndex)
        let point = points[idx].popLast()
        if points.last?.isEmpty == true {
            points.removeLast()
        }
        return point
    }
    
    public func forEach(_ block: (IndexPath, CGPoint, inout Bool) -> Void) {
        for (i, points) in enumerated() {
            for (j, point) in points.enumerated() {
                var stop = false
                block(IndexPath(item: j, section: i), point, &stop)
                if stop {
                    return
                }
            }
        }
    }
    
}
