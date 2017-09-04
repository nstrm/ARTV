//
//  Queue.swift
//  Television
//
//  Created by Walter Nordström on 2017-08-30.
//  Copyright © 2017 Walter Nordström. All rights reserved.
//

public struct Queue<T> {
    fileprivate var array = [T]()
    
    public var isEmpty: Bool {
        return array.isEmpty
    }
    
    public var count: Int {
        return array.count
    }
    
    init(fromList list: Array<T>) {
        self.array = list
    }
    
    public mutating func enqueue(_ element: T) {
        array.append(element)
    }
    
    public mutating func dequeue() -> T? {
        if isEmpty {
            return nil
        } else {
            let element = array.removeFirst()
            enqueue(element)
            return element
        }
    }
    
    public var front: T? {
        return array.first
    }
}

