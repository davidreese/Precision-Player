import Foundation
import AVKit
import MediaPlayer
#if os(iOS)
import UIKit
#endif

class AudioPlayerModel: ObservableObject, NowPlayable {
    @Published private(set) var player: AVAudioPlayer?
    
    @Published var currentTime: TimeInterval?
    @Published var isPlaying: Bool?
    
    // NowPlayable protocol properties
    var defaultAllowsExternalPlayback: Bool { true } // Allow external playback by default
    var defaultRegisteredCommands: [NowPlayableCommand] { [.play, .pause] }
    var defaultDisabledCommands: [NowPlayableCommand] { [] } // No commands disabled by default
    
    init(player: AVAudioPlayer?) {
        self.player = player
        
        self.currentTime = player?.currentTime
        self.isPlaying = player?.isPlaying
        
        configureControlCenterMedia() // Keep your existing setup
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.currentTime = player?.currentTime
            self.isPlaying = player?.isPlaying
            
            // Update Now Playing info in the timer as well
            if let player = self.player {
                self.handleNowPlayablePlaybackChange(playing: player.isPlaying,
                                                     metadata: NowPlayableDynamicMetadata(
                                                        rate: player.rate,
                                                        position: Float(player.currentTime),
                                                        duration: Float(player.duration),
                                                        currentLanguageOptions: [], // Update with actual language options if needed
                                                        availableLanguageOptionGroups: [] // Update with actual language options if needed
                                                     )
                )
            }
        }
        
        // Try to start a NowPlayable session when initialized
        do {
            try handleNowPlayableSessionStart()
        } catch {
            print("Error starting NowPlayable session: \(error)")
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
    
    // NowPlayable protocol methods
    func handleNowPlayableConfiguration(commands: [NowPlayableCommand],
                                        disabledCommands: [NowPlayableCommand],
                                        commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus,
                                        interruptionHandler: @escaping (NowPlayableInterruption) -> Void) throws {
        // You can use the configureRemoteCommands extension here if needed
        try configureRemoteCommands(commands, disabledCommands: disabledCommands, commandHandler: commandHandler)
        
        // Handle interruptions (not implemented in this example, but you would set up your logic here)
    }
    
    func handleNowPlayableSessionStart() throws {
        // Start your audio session or set playback state here (platform-dependent)
        // For example, on iOS, you might activate an AVAudioSession
    }
    
    func handleNowPlayableSessionEnd() {
        // End your audio session or reset playback state here (platform-dependent)
    }
    
    func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata) {
        // Update Now Playing info with static metadata
        setNowPlayingMetadata(metadata)
    }
    
    func handleNowPlayablePlaybackChange(playing: Bool, metadata: NowPlayableDynamicMetadata) {
        // Update Now Playing info with dynamic playback metadata
        setNowPlayingPlaybackInfo(metadata)
    }
}
