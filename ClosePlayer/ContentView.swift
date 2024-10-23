//
//  ContentView.swift
//  ClosePlayer
//
//  Created by David Reese on 6/14/23.
//

import SwiftUI
import AVKit
import Combine
//import Foundation


struct ContentView: View {
    @ObservedObject private var model: ContentModel = ContentModel()
//    @StateObject private var player: Player = Player()
//    @State private var url: URL?
    @State private var player: AVAudioPlayer?
//    private var player: Binding<AVAudioPlayer?> = Binding {
//        return nil
//    } set: { val in
//        not sure how to do this. currently just ripped out Player (commented out a lot of important lines in order to do that) and im trying to use AVAudioPlayer instead, but having a lot of trouble
//    }

    @State private var audioPlayer: AudioPlayer?

    @State private var isPresentingFileImporter = false
    
    @State private var heldTime: TimeInterval? = nil
    
    @State private var seekValue = ""
    @State private var jumpToValue = ""
    @State private var offsetValue = ""
    @State private var filename: String? = nil
    
    @State private var selectedSpeed: String = "1.0" // Default selection
    let speeds: [String] = ["0.5", "1.0", "1.25", "1.5", "2.0", "3.0"]
    
    init () {
//        model.startUpdating()
    }
    
    var body: some View {
        VStack {
            if let audioPlayer = audioPlayer {
                audioPlayer
                    .onTimeChange(action: { time in
                        withAnimation {
                            model.objectWillChange.send()
                        }
                    })
                    .padding(.horizontal)
                    .padding(.bottom)
            }
//            VideoPlayer(player: url != nil ? AVPlayer(url: url!) : nil)
//                .onChange(of: player.avPlayer?.rate, { oldValue, newValue in
//                    print("RATE: \(player.avPlayer?.rate)")
//                })
//                .cornerRadius(5)
                
            
            VStack {
                VStack {
//                    Spacer()
                    
                    Group {
                        HStack {
                            Button((filename != nil) ? "Imported: \(filename!)" : "Import") {
                                isPresentingFileImporter = true
                            }
                            
                            Spacer()
//                            Text(filename ?? "")
                        }
                        HStack {
                            Button("Hold") {
                                self.heldTime = player?.currentTime
                            }
                            Button("Return") {
//                                print(player.avPlayer)
                                guard let savedTime = heldTime else {
                                    return
                                }
                                player?.currentTime = savedTime - 2
                                play()
                            }
                            Spacer()
                        }
                        
                    }
                    
                    //                    Spacer()
                    
                    HStack {
                        TextField("Seek", text: self.$seekValue)
                        //                        .keyboardType(.numberPad)
                            .onReceive(Just(seekValue)) { newValue in
                                var filtered = newValue.filter { "–-0123456789".contains($0) }
                                if seekValue.count > 1 {
                                    var newValueWithoutFirst = newValue
                                    let first = newValueWithoutFirst.removeFirst()
                                    
                                    let filteredWithoutFirst = newValueWithoutFirst.filter { "0123456789".contains($0) }
                                    filtered = String(first) + filteredWithoutFirst
                                }
                                
                                if filtered != newValue {
                                    self.seekValue = filtered
                                }
                            }
                            .onSubmit {
                                print("Seeking...")
                                
                                
                                guard let player = player, let diff = Double(seekValue.replacingOccurrences(of: "–", with: "-")) else {
                                    print("Invalid seek input")
                                    return
                                }
                                
                                player.currentTime = player.currentTime + diff
                                
//                                player.scrub(seconds: diff)
                                seekValue = "-"
                                play()
                            }
                            .frame(maxWidth: 200)
                        
                        Spacer()
                    }
                    
                    HStack {
                        TextField("Jump to", text: self.$jumpToValue)
                        //                        .keyboardType(.numberPad)
                            .onReceive(Just(jumpToValue)) { newValue in
                                let filtered = newValue.filter { ":0123456789".contains($0) }
                                if filtered != newValue {
                                    self.jumpToValue = filtered
                                }
                            }
                            .onSubmit {
                                print("Jumping...")
                                
                                let offsetRes: Double? = Double(offsetValue.replacingOccurrences(of: "–", with: "-"))
                                if !offsetValue.isEmpty {
                                    if offsetRes == nil {
                                        print("Invalid offset value")
                                        return
                                    }
                                }
                                
                                let offset = offsetRes ?? 0.0
                                print("Offset: \(offset)")
                                
                                if let jumpToInSeconds = Double(jumpToValue) {
                                    player?.currentTime = jumpToInSeconds + offset
//                                    player.scrub(to: CMTime(seconds: jumpToInSeconds, preferredTimescale: timeScale))
                                    jumpToValue = ""
                                    play()
                                } else if let jumpToTI = convertToTimeInterval(from: jumpToValue) {
                                    player?.currentTime = jumpToTI + offset
//                                    player.scrub(to: CMTime(seconds: jumpToTI, preferredTimescale: timeScale))
                                    jumpToValue = ""
                                    play()
                                }
                            }
                            .frame(maxWidth: 135)
                        TextField("Offset", text: self.$offsetValue)
                            .onReceive(Just(offsetValue)) { newValue in
                                var filtered = newValue.filter { "–-+0123456789".contains($0) }
                                if offsetValue.count == 1 {
                                    filtered = newValue.filter { "+-–".contains($0) }
                                } else if offsetValue.count > 1 {
                                    var newValueWithoutFirst = newValue
                                    let first = newValueWithoutFirst.removeFirst()
                                    
                                    let filteredWithoutFirst = newValueWithoutFirst.filter { "0123456789".contains($0) }
                                    filtered = String(first) + filteredWithoutFirst
                                }
                                
                                if filtered != newValue {
                                    self.offsetValue = filtered
                                }
                            }
                            .frame(maxWidth: 65)
                        
                        Spacer()
                    }
                    
                    //                    Spacer()
                    
                    HStack {
                        Picker("Rate:", selection: $selectedSpeed) {
                            ForEach(speeds, id: \.self) { option in
                                Text("\(option)x")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedSpeed) {
//                            player.setRate(Float(value)!)
//                            player!.pause()
//                            player?.rate = Float(selectedSpeed)!
                            audioPlayer?.setRate(Float(selectedSpeed)!)
                        }
                        .frame(maxWidth: 200)
                        
                        Spacer()
                    }
//                    Spacer()
                    
                    
//                    HStack {
//                        if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
//                            ProgressView()
//                            Spacer()
//                        }
//                    }
                }.padding(.horizontal)
                
                Divider()
                
                VStack {
//                    Spacer()
                    HStack {
                        if let audioPlayer {
                            Text("TIME: \(audioPlayer.model.player.currentTime.rounded().formatted())")
                        } else {
                            Text("TIME: nil")
                        }
                        Spacer()
                    }
                    
                    //                    Spacer()
                    
                    HStack {
                        let color: Color = {
                            guard let savedSeconds = heldTime, let audioPlayer else {
                                return Color.primary
                            }
                            
                            let diff = audioPlayer.model.player.currentTime - savedSeconds
                            if diff < -10 {
                                return Color.orange
                            } else if diff < 0.3 && diff > -1 {
                                return Color.cyan
                            } else if diff > 250 {
                                return Color.red
                            } else {
                                return Color.primary
                            }
                        }()
                        Text("HELD: \(heldTime?.rounded().formatted() ?? "nil")")
                            .foregroundColor(color)
                        Spacer()
                    }
                    
                    //                    Spacer()
                    
                    HStack {
                        if let audioPlayer {
                            Text("DURATION: \(audioPlayer.model.player.duration.rounded().formatted())")
                        } else {
                            Text("DURATION: nil")
                        }
                        Spacer()
                    }
                    
                    Spacer()
                }.padding()
            }
        }
        .padding(.vertical)
        .frame(minWidth: 350, minHeight: 400)
        .fileImporter(isPresented: $isPresentingFileImporter, allowedContentTypes: [.audio, .mpeg4Movie, .video, .movie, .mp3], onCompletion: { result in
            do {
                let url = try result.get()

                guard url.startAccessingSecurityScopedResource() else {return}
                
                let player = try AVAudioPlayer(contentsOf: url)
                player.enableRate = true
                player.prepareToPlay()
                
                self.filename = url.lastPathComponent
                self.audioPlayer = AudioPlayer(player: player, title: filename!, artist: nil)
                self.audioPlayer?.setRate(Float(selectedSpeed)!)
                
                self.player = player
                
//                self.url = url
                self.heldTime = nil
                
                
                
//                print(self.player.avPlayer)
            } catch {
                print("Error importing audio file: \(error)")
            }
        })
    }
    
    func play() {
        audioPlayer?.play()
//        model.startUpdating()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
