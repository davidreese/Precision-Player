//
//  Player.swift
//  ClosePlayer
//
//  Created by David Reese on 6/15/23.
//  Imported from the YTS App, after having originally taken from <#SOURCE#>
//

import Foundation
import AVKit
import Combine
import SwiftUI
import MediaPlayer

let timeScale = CMTimeScale(1000)
let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)

final class Player: NSObject, ObservableObject {
    /// Display time that will be bound to the scrub slider.
    @Published var displayTime: TimeInterval = 0
    
    /// The observed time, which may not be needed by the UI.
    @Published var observedTime: TimeInterval = 0
    
    @Published var itemDuration: TimeInterval = 0
    fileprivate var itemDurationKVOPublisher: AnyCancellable!
    
    /// Publish timeControlStatus
    @Published var timeControlStatus: AVPlayer.TimeControlStatus = .paused
    fileprivate var timeControlStatusKVOPublisher: AnyCancellable!
    
    /// The AVPlayer
    @Published var avPlayer: AVPlayer?
    
    /// Time observer.
    fileprivate var periodicTimeObserver: Any?
    
    /// The rate that that player should be set to play at.
    @Published private(set) var setRate: Float = 1.0
    
    var scrubState: PlayerScrubState = .reset {
        didSet {
            switch scrubState {
            case .reset:
                return
            case .scrubStarted:
                return
            case .scrubEnded(let seekTime):
                avPlayer?.seek(to: CMTime(seconds: seekTime, preferredTimescale: 1000))
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    init(avPlayer: AVPlayer) {
        self.avPlayer = avPlayer
        super.init()
        
        self.addPeriodicTimeObserver()
        self.addTimeControlStatusObserver()
        self.addItemDurationPublisher()
        
//        setupRemoteTransportControls()
    }
    
    deinit {
        removePeriodicTimeObserver()
        timeControlStatusKVOPublisher?.cancel()
        itemDurationKVOPublisher?.cancel()
    }
    
    func set(avPlayer: AVPlayer) {
        removePeriodicTimeObserver()
        timeControlStatusKVOPublisher?.cancel()
        itemDurationKVOPublisher?.cancel()
        
        self.avPlayer = avPlayer
        self.addPeriodicTimeObserver()
        self.addTimeControlStatusObserver()
        self.addItemDurationPublisher()
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(playerDidFinishPlaying),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: avPlayer.currentItem
            )
        
        addRateObserver()
        
//        setupRemoteTransportControls()
//        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        
//        commandCenter.playCommand.isEnabled = true
//        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        
        commandCenter.playCommand.addTarget { event in
                    if self.timeControlStatus == .paused {
                        self.play()
                        return .success
                    } else {
                        return .commandFailed
                    }
                }
                
                commandCenter.pauseCommand.addTarget { event in
                    if self.timeControlStatus == .playing {
                        self.pause()
                        return .success
                    } else {
                        return .commandFailed
                    }
                }
        
    }
    
    func play() {
        self.avPlayer?.play()
        self.setRate(setRate)
        setupRemoteTransportControls()
    }
    
    func pause() {
        self.avPlayer?.pause()
    }
    
    func scrub(to time: CMTime) {
        if let _ = self.avPlayer {
            self.avPlayer!.seek(to: time)
        }
    }
    
    func scrub(seconds: TimeInterval) {
        if let _ = self.avPlayer {
            self.avPlayer!.seek(to: self.avPlayer!.currentTime().timeWithOffset(offset: seconds))
        }
    }
    
    func setRate(_ rate: Float) {
        self.avPlayer?.rate = rate
        self.setRate = rate
    }
    
    @objc func playerDidFinishPlaying() {
    }
    
    func addRateObserver() {
        avPlayer?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if let avPlayer = avPlayer, avPlayer.rate > 0 {
                if avPlayer.rate != self.setRate {
//                    Updates actual rate to equal the set one
                    avPlayer.rate = self.setRate
                }
            }
        }
    }
    
    fileprivate func addPeriodicTimeObserver() {
        self.periodicTimeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] (time) in
            guard let self = self else { return }
            
            // Always update observed time.
            withAnimation {
                self.observedTime = time.seconds
//                autoreleasepool {
//                }
            }
            
            switch self.scrubState {
            case .reset:
                withAnimation {
                    self.displayTime = time.seconds
                }
            case .scrubStarted:
                // When scrubbing, the displayTime is bound to the Slider view, so
                // do not update it here.
                break
            case .scrubEnded(let seekTime):
                withAnimation {
                    self.scrubState = .reset
                    self.displayTime = seekTime
                }
            }
        }
    }
    
    fileprivate func removePeriodicTimeObserver() {
        guard let periodicTimeObserver = self.periodicTimeObserver else {
            return
        }
        avPlayer?.removeTimeObserver(periodicTimeObserver)
        self.periodicTimeObserver = nil
    }
    
    fileprivate func addTimeControlStatusObserver() {
        timeControlStatusKVOPublisher = avPlayer?
            .publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (newStatus) in
                guard let self = self else { return }
                withAnimation {
                    self.timeControlStatus = newStatus
                }
            })
    }
    
    fileprivate func addItemDurationPublisher() {
        itemDurationKVOPublisher = avPlayer?
            .publisher(for: \.currentItem?.duration)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (newStatus) in
                guard let newStatus = newStatus,
                      let self = self else { return }
                withAnimation {
                    self.itemDuration = newStatus.seconds
                }
            })
    }
    
    enum PlayerScrubState {
        case reset
        case scrubStarted
        case scrubEnded(TimeInterval)
    }
}

extension CMTime {
    func timeWithOffset(offset: TimeInterval) -> CMTime {
        
        let seconds = CMTimeGetSeconds(self)
        let secondsWithOffset = seconds + offset
        
        return CMTimeMakeWithSeconds(secondsWithOffset, preferredTimescale: timescale)
        
    }
}
