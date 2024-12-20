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
    @ObservedObject private(set) var model: AudioPlayerModel
    
    struct UI {
        static let cornerRadius = 8.0
    }
    
    //    init(player: StateObject<Player>) {
    //        self.player = player
    //    }
    
    @State var showsTimeRemaining: Bool = false
    
    init(player: AVAudioPlayer, title: String, artist: String? = nil) {
        self.model = AudioPlayerModel(player: player, title: title, artist: artist)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: UI.cornerRadius)
            .fill(.thickMaterial)
            .shadow(radius: 3)
            .frame(height: 60)
            .frame(minWidth: 300)
            .overlay {
                HStack(spacing: 10) {
                    Spacer()
                    Button(action: {
                        //                        player.wrappedValue.play()
                        if !(model.player.isPlaying) {
                            model.play()
                        } else {
                            model.pause()
                        }
                    }, label: {
                        Image(systemName: model.player.isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15)
                    }).buttonStyle(.borderless)
                    
                    Divider().padding(.vertical, 7)
                    
                    VStack(spacing: 0) {
                        Spacer()
                        Spacer()
                        Spacer()
                        
                        HStack {
                            //                            Spacer()
                            ProgressView(value: model.player.currentTime, total: model.player.duration)
                                .progressViewStyle(FocusedLinearProgressViewStyle())
                            Spacer()
                        }
                        HStack {
                            //                            if model.player.currentTime < 3600 {
                            HStack {
                                Text(timeFormatted(totalSeconds: model.player.currentTime))
                                Spacer()
                            }
                            Spacer()
                            Group {
                                //                                let seconds = showsTimeRemaining ? model.player.duration - model.player.currentTime : model.player.duration
                                
                                if !showsTimeRemaining {
                                    HStack {
                                        Spacer()
                                        Text(timeFormatted(totalSeconds: model.player.duration))
                                    }
                                    //                                        .frame(width: 45)
                                } else {
                                    HStack {
                                        Spacer()
                                        Text("-" + timeFormatted(totalSeconds: model.player.duration - model.player.currentTime))
                                    }
                                    //                                        .frame(width: 53)
                                }
                                
                            }
                            .onTapGesture {
                                showsTimeRemaining.toggle()
                            }
                            Spacer()
                        }
                        .font(.callout)
//                        .bold()
                        
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                    
                    
                    /*
                     */
                    
                    //                    Spacer()
                    
                }
            }
        
    }
    
    func onTimeChange(action: @escaping (TimeInterval) -> Void) -> AudioPlayer {
        model.onTimeChange = action
        return self
    }
    
    func setRate(_ rate: Float) {
        model.setPlaybackRate(rate)
    }
    
    func play() {
        model.play()
    }
    
    func swap(player: AVAudioPlayer, title: String, artist: String? = nil) {
        self.model.swap(player: player, title: title, artist: artist)
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

struct AudioPlayer_Previews: PreviewProvider {
    static var previews: some View {
        let url = Bundle.main.url(forResource: "beethoven-fifth", withExtension: "mp3")!
        let audioPlayer = try? AVAudioPlayer(contentsOf: url)
        AudioPlayer(player: audioPlayer!, title: "Test")
    }
}
