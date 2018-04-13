//
//  AsynchronousOperation.swift
//  ImagePicker
//
//  Created by Peter Stajger on 13/04/2018.
//  Copyright © 2018 Inloop. All rights reserved.
//

import Foundation

///
/// Provides primitives for wrapping Operation with asynchronous code that can
/// be enqueued in a OperationQueue and run serially.
///
class AsynchronousOperation : Foundation.Operation {
    
    var stateFinished: Bool = false {
        willSet { willChangeValue(forKey: "isFinished") }
        didSet { didChangeValue(forKey: "isFinished") }
    }
    var stateExecuting: Bool = false {
        willSet { willChangeValue(forKey: "isExecuting") }
        didSet { didChangeValue(forKey: "isExecuting") }
    }
    
    override var isFinished: Bool {
        return stateFinished
    }
    
    override var isExecuting: Bool {
        return stateExecuting
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override func main() {
        
        if isCancelled {
            completeOperation()
        }
        else {
            stateExecuting = true
            execute()
        }
    }
    
    func execute() {
        fatalError("This method has to be overriden")
    }
    
    func completeOperation() {
        
        if self.stateExecuting == true {
            self.stateExecuting = false
        }
        
        if self.stateFinished == false {
            self.stateFinished = true
        }
    }
    
}
