//
//  ContentModel.swift
//  ClosePlayer
//
//  Created by David Reese on 6/14/23.
//

import Foundation
import AVFAudio

class ContentModel: ObservableObject {
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.objectWillChange.send()
        }
    }
}
