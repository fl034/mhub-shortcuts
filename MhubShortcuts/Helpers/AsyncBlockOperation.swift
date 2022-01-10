//
//  AsyncBlockOperation.swift
//  ORSYfleet
//
//  Created by Frank Lehmann on 08.06.18.
//  Copyright © 2018 Stoll Von Gati. All rights reserved.
//

import Foundation

extension OperationQueue {    
    /// This adds a completion operation at the end of the operations list.
    /// Call this method only after adding all the operations to the queue.
    func onCompletion(do completionHandler: @escaping ()->(), queue: DispatchQueue? = nil) {
        if operations.count == 0 {
            print("Called onCompletion before added operations.")
            return
        }
        
        let completionOperation = BlockOperation {
            if queue != nil {
                queue!.async {
                    completionHandler()
                }
            } else {
                completionHandler()
            }
        }
        
        operations.forEach {
            completionOperation.addDependency($0)
        }
        
        addOperation(completionOperation)
    }
}

/// See: https://gist.github.com/tomkowz/2734cf25318b7cfcd475b1149ab3ee7a
class AsyncBlockOperation: Operation {
    typealias Block = (@escaping () -> Void) -> Void
    
    private let block: Block
    private var _executing = false
    private var _finished = false
    
    init(block: @escaping Block) {
        self.block = block
        super.init()
    }
    
    override func start() {
        guard (self.isExecuting || self.isCancelled) == false else { return }
        self.isExecuting = true
        self.block(finish)
    }
    
    private func finish() {
        self.isExecuting = false
        self.isFinished = true
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        get { return _executing }
        set {
            let key = "isExecuting"
            willChangeValue(forKey: key)
            _executing = newValue
            didChangeValue(forKey: key)
        }
    }
    
    override var isFinished: Bool {
        get { return _finished }
        set {
            let key = "isFinished"
            willChangeValue(forKey: key)
            _finished = newValue
            didChangeValue(forKey: key)
        }
    }
}

extension OperationQueue {
    func addAsyncOperation(_ block: @escaping AsyncBlockOperation.Block) {
        let operation = AsyncBlockOperation(block: block)
        addOperation(operation)
    }
}

class AsyncOverridableOperation: Operation {
        
    func runAsync() {
        fatalError("Don't call super.")
    }
    
    private var _executing = false
    private var _finished = false
        
    override func start() {
        guard (self.isExecuting || self.isCancelled) == false else { return }
        self.isExecuting = true
        self.runAsync()
    }
    
    func finish() {
        self.isExecuting = false
        self.isFinished = true
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        get { return _executing }
        set {
            let key = "isExecuting"
            willChangeValue(forKey: key)
            _executing = newValue
            didChangeValue(forKey: key)
        }
    }
    
    override var isFinished: Bool {
        get { return _finished }
        set {
            let key = "isFinished"
            willChangeValue(forKey: key)
            _finished = newValue
            didChangeValue(forKey: key)
        }
    }
}
