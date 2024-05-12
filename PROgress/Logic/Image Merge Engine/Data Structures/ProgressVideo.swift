//
//  ProgressVideo.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 09..
//

import Foundation
import SwiftData

struct ProgressVideo: Hashable {
    var videoId: UUID
    var url: URL
    var resolution: CGSize
    var name: String = "Progress Video"
    
    /// Signals whether the video had already been persisted in the background.
    var persisted: Bool = false
    
    func hash(into hasher: inout Hasher) {
        videoId.hash(into: &hasher)
    }
    
    func model(withLocalIdentifier localIdentifier: String) -> Model {
        return ProgressVideo.Model(localIdentifier: localIdentifier, name: self.name)
    }
    
    /// The persistable version of this type.
    @Model
    class Model {
        @Attribute(.unique)
        var localIdentifier: String
        
        var name: String
        var createdAt: Date
        
        init(localIdentifier: String, name: String, createdAt: Date = .now) {
            self.localIdentifier = localIdentifier
            self.name = name
            self.createdAt = createdAt
        }
        
        static func descriptorForAllItems() -> FetchDescriptor<ProgressVideo.Model> {
            .init(sortBy: [.init(\.createdAt, order: .reverse)])
        }
    }
}

// FIXME: when same-type requirements will be possible for parameter packs switch to:
// extension Predicate where repeat each Input == (ProgressVideo.Model) { ... }

extension Predicate<ProgressVideo.Model> {
    static func matchingLocalIdentifiers(_ localIdentifiers: [String]) -> Predicate<ProgressVideo.Model> {
        #Predicate<ProgressVideo.Model> {
            localIdentifiers.contains($0.localIdentifier)
        }
    }
    
    static func matchingLocalIdentifier(_ localIdentifier: String) -> Predicate<ProgressVideo.Model> {
        #Predicate<ProgressVideo.Model> {
            $0.localIdentifier == localIdentifier
        }
    }
}
