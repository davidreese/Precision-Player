//
//  AudioPlayerModel.swift
//  ClosePlayer
//
//  Created by David Reese on 8/13/24.
//

import Foundation
import AVKit
//import SwiftUI
import MediaPlayer
#if os(iOS)
    import UIKit
#endif

class AudioPlayerModel: ObservableObject {
    @Published private(set) var player: AVAudioPlayer?
    
    @Published var currentTime: TimeInterval?
    @Published var isPlaying: Bool?
    
    init(player: AVAudioPlayer?) {
        self.player = player
        
        self.currentTime = player?.currentTime
        self.isPlaying = player?.isPlaying
        
        setupRemoteTransportControls()
        configureControlCenterMedia()
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.currentTime = player?.currentTime
            
            //            withAnimation {
            self.isPlaying = player?.isPlaying
            
            self.setupNowPlaying()
            //            }
            
            //            self.updateNowPlayingInfo()
        }
    }
    
    private func configureControlCenterMedia() {
        guard let player = player else {
            print("Can't set up remote transport controls because player is nil")
            return
        }
        
        #if os(iOS)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        #endif
//            UIApplication.shared.beginReceivingRemoteControlEvents()
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.nextTrackCommand.isEnabled = false
            commandCenter.previousTrackCommand.isEnabled = false
            commandCenter.togglePlayPauseCommand.isEnabled = true
        
            commandCenter.playCommand.addTarget { event in
                if !player.isPlaying {
                    player.play()
                    return .success
                } else {
                    return .commandFailed
                }
            }
            
            commandCenter.pauseCommand.addTarget { event in
                if player.isPlaying {
                    player.pause()
                    return .success
                } else {
                    return .commandFailed
                }
            }
            
            var nowPlayingInfo: [String: Any] = [:]
            nowPlayingInfo[MPMediaItemPropertyTitle] = "audio?.title"
            nowPlayingInfo[MPMediaItemPropertyArtist] = "audio?.author.name"
            
        /*
            let lightTrait = UITraitCollection(userInterfaceStyle: .light)
            if let image = UIImage(named: "Logo", in: nil, compatibleWith: lightTrait) {
                nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
                }
            }*/
            
            commandCenter.changePlaybackPositionCommand.isEnabled = true
            
            commandCenter.changePlaybackPositionCommand.addTarget { event in
                guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                    return .commandFailed
                }
//                let time = CMTime(seconds: event.positionTime, preferredTimescale: 1_000_000)
                self.player?.currentTime = event.positionTime
                return .success
            }
            
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                guard let player = self.player else {
                    print("Can't set up remote transport controls because player is nil (2)")
                    return
                }
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
                nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }

    
    func setupRemoteTransportControls() {
        guard let player = player else {
            print("Can't set up remote transport controls because player is nil")
            return
        }
        
        //        UIApplication.shared.beginReceivingRemoteControlEvents()
        //        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.stopCommand.isEnabled = false
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if !player.isPlaying {
                player.play()
                return .success
            } else {
                return .commandFailed
            }
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if player.isPlaying {
                player.pause()
                return .success
            } else {
                return .commandFailed
            }
        }
        
    }
    
    
    func setupNowPlaying() {
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "My Movie"
        
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.duration
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

}
