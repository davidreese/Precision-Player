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
    
    @State private var isPresentingFileImporter = false
    
    @State private var seekValue = ""
    @State private var jumpToValue = ""
    @State private var offsetValue = ""
    @State private var offsetIsOn: Bool = true
    @State private var filename: String? = nil
    
    @State private var selectedSpeed: String = "1.0" // Default selection
    let speeds: [String] = ["0.5", "1.0", "1.25", "1.5", "1.75", "2.0", "2.25", "2.5", "3.0"]
    
//    let windowId: String = ""
//    @Environment(\.scenePhase) private var scenePhase
    
    /*
    init (windowId: String) {
        print("Window id: \(windowId)")
        self.windowId = windowId
        //        model.startUpdating()
    }*/
    
    var body: some View {
        VStack {
            if let audioPlayer = model.audioPlayer {
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
                        }
                        HStack {
                            Button("Hold") {
                                model.hold()
                            }.keyboardShortcut(.init("s"), modifiers: [.command])
                            
                            Button("Return") {
                                model.returnAndPlay()
                            }.keyboardShortcut(.init("r"), modifiers: [.command])
                            
                            Spacer()
                        }
                        
                    }
                    
                    Divider()
                    
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
                                
                                guard let player = model.player, let diff = Double(seekValue.replacingOccurrences(of: "–", with: "-")) else {
                                    print("Invalid seek input")
                                    return
                                }
                                
                                player.currentTime = player.currentTime + diff
                                
                                //                                player.scrub(seconds: diff)
                                seekValue = "-"
                                model.play()
                            }
                            .frame(maxWidth: 200)
                        
                        Spacer()
                    }
                    
                    
                    Divider()
                    
                    VStack {
                        HStack {
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
                                        
                                        let offset = offsetIsOn ? offsetRes ?? 0.0 : 0.0
                                        print("Offset: \(offset)")
                                        
                                        if let jumpToInSeconds = Double(jumpToValue) {
                                            model.player?.currentTime = jumpToInSeconds + offset
                                            //                                    player.scrub(to: CMTime(seconds: jumpToInSeconds, preferredTimescale: timeScale))
                                            jumpToValue = ""
                                            model.play()
                                        } else if let jumpToTI = convertToTimeInterval(from: jumpToValue) {
                                            model.player?.currentTime = jumpToTI + offset
                                            //                                    player.scrub(to: CMTime(seconds: jumpToTI, preferredTimescale: timeScale))
                                            jumpToValue = ""
                                            model.play()
                                        }
                                    }
                                //                                .frame(width: 130)
                                //                            .frame(maxWidth: 65)
                            }.frame(maxWidth: 200)
                            
                            Spacer()
                        }
                        
                        HStack {
                            HStack {
                                TextField("Offset", text: self.$offsetValue)
                                    .disabled(!offsetIsOn)
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
                                    }//.frame(maxWidth: 100)
                                
                                Toggle(isOn: $offsetIsOn, label: {
                                    if offsetIsOn {
                                        Image(systemName: "lightswitch.on")
                                    } else {
                                        Image(systemName: "lightswitch.off")
                                    }
                                })
                                .toggleStyle(.button)
                            }.frame(maxWidth: 200)
                            
                            Spacer()
                        }
                    }
                    Divider()
                    
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
                            model.audioPlayer?.setRate(Float(selectedSpeed)!)
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
                    
                    
                    Divider()
                    
                    VStack {
                        HStack {
                            if let audioPlayer = model.audioPlayer {
                                Text("TIME: \(audioPlayer.model.player.currentTime.rounded().formatted())")
                            } else {
                                Text("TIME: nil")
                            }
                            Spacer()
                        }
                        
                        //                    Spacer()
                        
                        HStack {
                            let color: Color = {
                                guard let savedSeconds = model.heldTime, let audioPlayer = model.audioPlayer else {
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
                            Text("HELD: \(model.heldTime?.rounded().formatted() ?? "nil")")
                                .foregroundColor(color)
                            Spacer()
                        }
                        
                        //                    Spacer()
                        
                        HStack {
                            if let audioPlayer = model.audioPlayer {
                                Text("DURATION: \(audioPlayer.model.player.duration.rounded().formatted())")
                            } else {
                                Text("DURATION: nil")
                            }
                            Spacer()
                        }
                        
                        Spacer()
                    }.padding(.top)
                }.padding(.horizontal)
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
                
                if self.model.audioPlayer == nil {
                    self.model.audioPlayer = AudioPlayer(player: player, title: filename!, artist: nil)
                    self.model.audioPlayer!.setRate(Float(selectedSpeed)!)
                } else {
                    self.model.audioPlayer!.swap(player: player, title: filename!, artist: nil)
                    self.offsetValue = ""
                }
                
                self.model.player = player
                
                //                self.url = url
                self.model.heldTime = nil
                
                self.selectedSpeed = "1.0"
                
                //                print(self.player.avPlayer)
            } catch {
                print("Error importing audio file: \(error)")
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
