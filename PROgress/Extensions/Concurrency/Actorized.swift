//
//  Actorized.swift
//  PROgress
//
//  Created by Balázs Erdész on 23/04/2024.
//

import Foundation

actor Actorized<T: Sendable> {
    private(set) var value: T!
    
    init(value: T! = nil) {
        self.value = value
    }
    
    init<V>(value: V? = nil) where T == Optional<V> {
        self.value = value
    }
    
    func set(to value: T) {
        self.value = value
    }
}

extension Sendable {
    static func makeActorized() -> Actorized<Self> {
        return Actorized(value: nil)
    }
    
    static func makeActorized<V>(value: V? = nil) -> Actorized<Self> where Self == Optional<V> {
        return Actorized(value: value)
    }
}
