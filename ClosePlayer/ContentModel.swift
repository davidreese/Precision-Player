//
//  ContentModel.swift
//  ClosePlayer
//
//  Created by David Reese on 6/14/23.
//

import Foundation
import AVFAudio

class ContentModel: ObservableObject {
    
    var timer: Timer? = nil
    
    init() {
    }
    
    func stopUpdating() {
        timer?.invalidate()
    }
    
    func startUpdating() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.objectWillChange.send()
        }
    }
}
