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
    @StateObject private var model: ContentModel = ContentModel()
    @StateObject private var player: Player = Player()
    
    @State private var isPresentingFileImporter = false
    
    @State private var savedTime: CMTime?
    
    @State private var seekValue = ""
    @State private var jumpToValue = ""
    @State private var filename: String?
    
    @State private var selectedSpeed: String = "1.0" // Default selection
    let speeds: [String] = ["0.5", "1.0", "1.25", "1.5", "2.0", "3.0"]
    
    var body: some View {
        VStack {
            VideoPlayer(player: player.avPlayer)
                .cornerRadius(5)
                .padding(.horizontal)
            
            HStack {
                VStack {
                    Spacer()
                    
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
                                self.savedTime = player.avPlayer?.currentTime()
                            }
                            Button("Return") {
                                guard let savedTime = savedTime else {
                                    return
                                }
                                player.scrub(to: savedTime.timeWithOffset(offset: -2))
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
                                let filtered = newValue.filter { "–-0123456789".contains($0) }
                                if filtered != newValue {
                                    self.seekValue = filtered
                                }
                            }
                            .onSubmit {
                                print("Seeking...")
                                
                                guard let diff = Double(seekValue.replacingOccurrences(of: "–", with: "-")) else {
                                    print("Invalid seek input")
                                    return
                                }
                                
                                player.scrub(seconds: diff)
                                seekValue = "-"
                                player.play()
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
                                
                                if let jumpToInSeconds = Double(jumpToValue) {
                                    player.scrub(to: CMTime(seconds: jumpToInSeconds, preferredTimescale: timeScale))
                                    jumpToValue = ""
                                    player.play()
                                } else if let jumpToTI = convertToTimeInterval(from: jumpToValue) {
                                    player.scrub(to: CMTime(seconds: jumpToTI, preferredTimescale: timeScale))
                                    jumpToValue = ""
                                    player.play()
                                }
                            }
                            .frame(maxWidth: 200)
                        
                        Spacer()
                    }
                    
                    //                    Spacer()
                    
                    HStack {
                        /*
                         Menu {
                         Button(action: {
                         //                                            Haptics.shared.play(.rigid)
                         player.setRate(0.5)
                         }) {
                         Label {
                         Text("0.5x")
                         } icon: {
                         Image(nsImage: NSImage(systemSymbolName: "checkmark", accessibilityDescription: )!)
                         }
                         
                         //                                Label("0.5x", systemImage: (player.setRate == 0.5) ? "checkmark" : "tortoise")
                         }
                         Button(action: {
                         //                                            Haptics.shared.play(.rigid)
                         player.setRate(0.75)
                         }) {
                         Label("0.75x", systemImage: (player.setRate == 0.75) ? "checkmark" : "")
                         }
                         Button(action: {
                         //                                            Haptics.shared.play(.rigid)
                         player.setRate(1)
                         }) {
                         Label("1x", systemImage: (player.setRate == 1) ? "checkmark" : "figure.walk")
                         }
                         Button(action: {
                         //                                            Haptics.shared.play(.rigid)
                         player.setRate(1.5)
                         }) {
                         Label("1.5x", systemImage: (player.setRate == 1.5) ? "checkmark" : "")
                         }
                         Button(action: {
                         //                                            Haptics.shared.play(.rigid)
                         player.setRate(2)
                         }) {
                         Label("2x", systemImage: (player.setRate == 2) ? "checkmark" : "hare")
                         }
                         } label: {
                         Image(systemName: "speedometer")
                         .resizable()
                         .foregroundColor(.gray)
                         .frame(width: 20, height: 20)
                         }
                         */
                        
                        Picker("Rate:", selection: $selectedSpeed) {
                            ForEach(speeds, id: \.self) { option in
                                Text("\(option)x")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedSpeed) { value in
                            player.setRate(Float(value)!)
                        }
                        .frame(maxWidth: 200)
                        Spacer()
                    }
                    Spacer()
                    
                    
                    HStack {
                        if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                            ProgressView()
                            Spacer()
                        }
                    }
                }.padding(.horizontal)
                
                Divider()
                //                Spacer()
                
                VStack {
                    Spacer()
                    HStack {
                        Text("TIME: \(player.displayTime.rounded().formatted())")
                        Spacer()
                    }
                    
                    //                    Spacer()
                    
                    HStack {
                        let color: Color = {
                            guard let savedSeconds = savedTime?.seconds else {
                                return Color.primary
                            }
                            
                            let diff = player.displayTime - savedSeconds
                            if diff > 0 && diff < 200 {
                                return Color.orange
                            } else if diff > 200 {
                                return Color.red
                            } else {
                                return Color.primary
                            }
                        }()
                        Text("HELD: \(savedTime?.seconds.rounded().formatted() ?? "nil")")
                            .foregroundColor(color)
                        Spacer()
                    }
                    
                    //                    Spacer()
                    
                    HStack {
                        Text("DURATION: \(player.itemDuration.rounded().formatted())")
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical)
        .fileImporter(isPresented: $isPresentingFileImporter, allowedContentTypes: [.audio, .mpeg4Movie, .video], onCompletion: { result in
            
            do {
                let url = try result.get()
                let ap = AVPlayer(url: url)
                self.player.set(avPlayer: ap)
                
                self.filename = url.lastPathComponent
            } catch {
                print("Error importing audio file: \(error)")
            }
        })
    }
    
    
    func play() {
        player.play()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
