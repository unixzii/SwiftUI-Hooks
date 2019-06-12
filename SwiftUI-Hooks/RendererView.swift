//
//  RendererView.swift
//  SwiftUI-Hooks
//
//  Created by Hongyu on 6/12/19.
//  Copyright © 2019 Cyandev. All rights reserved.
//

import SwiftUI
import Combine

protocol RendererViewHooks {
    
    typealias StateSetter<T> = (T) -> ()
    typealias EffectCallback = () -> ()
    
    /// Returns a stateful value, and a closure to update it.
    ///
    /// During the initial render, the returned state is the same as the value passed
    /// as the first argument (initial).
    ///
    /// - Parameter initial: The initial value.
    func useState<S>(initial: S) -> (S, StateSetter<S>)
    
    /// Same as `useEffect(_:dep:)` but the callback will get called every
    /// time the view is updated.
    ///
    /// - Parameter cb: The callback closure.
    func useEffect(_ cb: @escaping EffectCallback)
    
    /// Accepts a function that contains imperative, possibly effectful code.
    ///
    /// The closure passed to `useEffect` will run after the render is committed
    /// to the screen, if the dependency object is different from the one you passed
    /// last time. And if you need the callback to be called only once (just like what
    /// `onAppear(perform:)` does), you can pass
    /// `RendererView.triggerOnce` as the dependency object.
    ///
    /// - Parameter cb: The callback closure.
    /// - Parameter dep: The dependency object.
    func useEffect<D>(_ cb: @escaping EffectCallback, dep: D) where D: Hashable
    
}

extension RendererViewHooks {
    
    typealias ReducerFunc<S, A> = (S, A) -> S
    typealias DispatchFunc<A> = (A) -> ()
    
    func useReducer<S, A>(_ reducer: @escaping ReducerFunc<S, A>,
                          initial: S) -> (S, DispatchFunc<A>) {
        let (state, setState) = useState(initial: initial)
        
        let dispatch: DispatchFunc<A> = {
            let newState = reducer(state, $0)
            setState(newState)
        }
        return (state, dispatch)
    }
    
}

struct RendererView : View {
    
    struct TriggerOnceDep : Hashable {
        // Tag dep type for effects that should be called only once.
    }
    
    static let triggerOnce = TriggerOnceDep()
    
    fileprivate class InternalState : BindableObject, RendererViewHooks {
        
        struct AlwaysTriggerDep : Hashable {
            // Tag dep type for effects that should be called every
            // time the view is updated.
        }
        
        var stateSlots = [Any]()
        var effectDepSlots = [Any]()
        var pendingEffects = [EffectCallback]()
        var initialRendering = true
        var updatingScheduled = false
        var didChange = PassthroughSubject<InternalState, Never>()
        
        enum HookType {
            case useState
            case useEffect
        }
        
        var callCounter = [HookType:Int]()
        
        func useState<S>(initial: S) -> (S, StateSetter<S>) {
            let index: Int
            if initialRendering {
                stateSlots.append(initial)
                index = stateSlots.count - 1
            } else {
                index = slotIndex(for: .useState)
            }
            
            let setter: StateSetter<S> = {
                self.stateSlots[index] = $0
                self.scheduleUpdating()
            }
            
            return (stateSlots[index] as! S, setter)
        }
        
        func useEffect(_ cb: @escaping EffectCallback) {
            useEffect(cb, dep: AlwaysTriggerDep())
        }
        
        func useEffect<D>(_ cb: @escaping EffectCallback, dep: D) where D : Hashable {
            if initialRendering {
                effectDepSlots.append(dep)
                pendingEffects.append(cb)
            } else {
                // Fast path for `TriggerOnceDep`.
                guard !(dep is TriggerOnceDep) else {
                    return
                }
                
                let index = slotIndex(for: .useEffect)
                let lastDep = effectDepSlots[index]
                
                if dep is AlwaysTriggerDep || (lastDep as! D) != dep {
                    effectDepSlots[index] = dep
                    pendingEffects.append(cb)
                }
            }
        }
        
        func slotIndex(for type: HookType) -> Int {
            var count: Int! = callCounter[type]
            if count != nil {
                count = count + 1
            } else {
                count = 1
            }
            callCounter[type] = count
            return count - 1
        }
        
        func scheduleUpdating() {
            guard !updatingScheduled else {
                return
            }
            
            updatingScheduled = true
            OperationQueue.main.addOperation {
                self.didChange.send(self)
                self.updatingScheduled = false
            }
        }
        
        func willBeginRendering() {
            callCounter.removeAll()
        }
        
        func willFinishRendering() {
            initialRendering = false
            OperationQueue.main.addOperation {
                for cb in self.pendingEffects {
                    cb()
                }
                self.pendingEffects.removeAll()
            }
        }
        
    }
    
    // To make compiler happy, `AnyView` type is required.
    typealias Renderer = (RendererViewHooks) -> AnyView
    
    fileprivate let renderer: Renderer
    @ObjectBinding fileprivate var internalState = InternalState()
    
    init(_ renderer: @escaping Renderer) {
        self.renderer = renderer
    }
    
    var body: some View {
        internalState.willBeginRendering()
        let content = renderer(internalState)
        internalState.willFinishRendering()
        
        return content
    }
    
}
