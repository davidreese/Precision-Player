//
//  AudioPlayer.swift
//  ClosePlayer
//
//  Created by David Reese on 4/12/24.
//

import SwiftUI
import AVKit
import MediaPlayer

struct AudioPlayer: View {
//    var player: StateObject<Player>
    @ObservedObject var model: AudioPlayerModel
    
    struct UI {
        static let cornerRadius = 6.0
    }
    
//    init(player: StateObject<Player>) {
//        self.player = player
//    }
    
    init(player: AVAudioPlayer?) {
        self.model = AudioPlayerModel(player: player)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: UI.cornerRadius)
            .fill(Color.gray)
            .shadow(radius: 3)
            .frame(height: 60)
            .overlay {
                HStack(spacing: 10) {
                    Spacer()
                    Button(action: {
//                        player.wrappedValue.play()
                        if !(model.isPlaying ?? false) {
                            model.player?.play()
                        } else {
                            model.player?.pause()
                        }
                    }, label: {
                        Image(systemName: model.isPlaying ?? false ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15)
                    }).buttonStyle(.borderless)
                    
                    Text(timeFormatted(totalSeconds: model.currentTime))
                    
                    if let currentTime = model.currentTime, let duration = model.player?.duration {
                        ProgressView(value: currentTime, total: duration)
                            .progressViewStyle(.linear)
                    } else {
                        ProgressView(value: 0, total: 1)
                            .progressViewStyle(.linear)
                    }
                    
                    Text(timeFormatted(totalSeconds: model.player?.duration))
                    
                    Spacer()
                    
                }
            }
        
    }
        
    
    
    /// Imported from YTS-App
    func timeFormatted(totalSeconds: TimeInterval?) -> String {
        guard let totalSeconds = totalSeconds else {
            return "--:--"
        }
        let seconds: Int = Int((totalSeconds).truncatingRemainder(dividingBy: 60))
        let minutes: Int = Int(((totalSeconds / 60.0).truncatingRemainder(dividingBy: 60)))
        let hours: Int = Int(((totalSeconds / 3600).truncatingRemainder(dividingBy: 60)))
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    func timeFormattedMini(totalSeconds: TimeInterval) -> String {
        let seconds: Int = Int((totalSeconds).truncatingRemainder(dividingBy: 60))
        let minutes: Int = Int(((totalSeconds / 60.0).truncatingRemainder(dividingBy: 60)))
        let hours: Int = Int(((totalSeconds / 3600.0).truncatingRemainder(dividingBy: 60)))
        if hours > 0 {
            var str = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            if str.first == "0" {
                str.removeFirst()
            }
            return str
        } else {
            var str = String(format: "%02d:%02d", minutes, seconds)
            if str.first == "0" {
                str.removeFirst()
            }
            return str
        }
    }
}
