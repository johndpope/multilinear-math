//
//  Utilities.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation
import Accelerate

public protocol Number: Comparable {
    init(_ value: Int)
    init(_ value: Float)
    init(_ value: Double)
    
    func + (lhs: Self, rhs: Self) -> Self
    func - (lhs: Self, rhs: Self) -> Self
    func * (lhs: Self, rhs: Self) -> Self
    func / (lhs: Self, rhs: Self) -> Self
}

extension Double : Number {}
extension Float : Number {}
extension Int : Number {}
extension Int64 : Number {}

public protocol IntegerType {
    var value: Int {get}
}
extension Int: IntegerType {
    public var value: Int {
        get{
            return self
        }
    }
}

// credit for the Unsafeable protocol to Chris Liscio https://github.com/liscio
/// A CollectionType that can perfom functions on its Unsafe(Mutable)BufferPointer
public protocol Unsafeable: CollectionType {
    /// Perform the a function with a UnsafeBufferPointer to this collection
    func withUnsafeBufferPointer<R>(@noescape body: (UnsafeBufferPointer<Generator.Element>) throws -> R) rethrows -> R
    /// Perform the a function with a UnsafeMutableBufferPointer to this collection
    mutating func withUnsafeMutableBufferPointer<R>(@noescape body: (inout UnsafeMutableBufferPointer<Generator.Element>) throws -> R) rethrows -> R
}
public extension Unsafeable {
    func withUnsafeBufferPointer<R>(@noescape body: (UnsafeBufferPointer<Generator.Element>) throws -> R) -> R? {
        return withUnsafeBufferPointer(body)
    }
    mutating func withUnsafeMutableBufferPointer<R>(@noescape body: (inout UnsafeMutableBufferPointer<Generator.Element>) throws -> R) -> R? {
        return withUnsafeMutableBufferPointer(body)
    }
}

public typealias UnsafeBuffer = Unsafeable

extension Array : Unsafeable {}
extension ArraySlice : Unsafeable {}


/// combine two arrays (preferably of same size, else smaller size is used) with the combineFunction
func arrayCombine<A, B, R> (arrayA: [A], arrayB: [B], combineFunction: (a: A, b: B) -> R) -> [R] {
    let length = min(arrayA.count, arrayB.count)
    var result = [R]()
    for i in 0..<length {
        result.append(combineFunction(a: arrayA[i], b: arrayB[i]))
    }
    return result
}
public extension Array {
    /// Combine this array with another array and a given combineFunction
    func combineWith<E, R>(array: [E], combineFunction: (t: Element, e: E) -> R) -> [R] {
        return arrayCombine(self, arrayB: array, combineFunction: combineFunction)
    }
    
    /// Safe access to array elements
    subscript (safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension Unsafeable where Generator.Element: Equatable, Index == Int {
    ///remove the given values from this array
    func removeValues(values: [Generator.Element]) -> [Generator.Element] {
        var returnArray = Array(self)
        for value in values {
            if let index = returnArray.indexOf(value) {
                returnArray.removeAtIndex(index)
                
            }
        }
        return returnArray
    }
}

public func squaredDistance(a: [Float], b: [Float]) -> Float {
    return a.combineWith(b, combineFunction: {($0-$1)*($0-$1)}).reduce(0, combine: {$0+$1})
}

public extension String {
    
    /// `Int8` value of the first character
    var charValue: Int8 {
        get {
            return (self.cStringUsingEncoding(NSUTF8StringEncoding)?[0])!
        }
    }
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (r: Range<Int>) -> String {
        let start = startIndex.advancedBy(r.startIndex)
        let end = start.advancedBy(r.endIndex - r.startIndex)
        return self[start..<end]
    }
}


public extension Range {
    init(start: Element, distance: Element.Distance) {
        self.init(start: start, end: start.advancedBy(distance))
    }
}