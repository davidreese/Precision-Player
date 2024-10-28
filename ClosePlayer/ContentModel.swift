//
//  ContentModel.swift
//  ClosePlayer
//
//  Created by David Reese on 6/14/23.
//

import Foundation
import AVFAudio
import SwiftUI

class ContentModel: ObservableObject {
    @Published var heldTime: TimeInterval? = nil
    @Published var player: AVAudioPlayer?
    @Published var audioPlayer: AudioPlayer?
//    var timer: Timer? = nil
    
    init() {
    }
    
    func hold() {
        self.heldTime = player?.currentTime
    }
    
    func returnAndPlay() {
        guard let savedTime = heldTime else {
            return
        }
        player?.currentTime = savedTime - 2
        play()
    }
    
    func play() {
        audioPlayer?.play()
//        model.startUpdating()
    }
}
