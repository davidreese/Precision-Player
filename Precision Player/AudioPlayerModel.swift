import Foundation
import AVKit
import MediaPlayer
#if os(iOS)
    import UIKit
#endif

//import Swift .UI

class AudioPlayerModel: ObservableObject {

    enum PlayerState {
        case stopped
        case playing
        case paused
    }

    unowned let nowPlayableBehavior: NowPlayable

    @Published var player: AVAudioPlayer!

    private var playerState: PlayerState = .stopped {
        didSet {
            #if os(macOS)
            NSLog("%@", "**** Set player state \(playerState), playbackState \(MPNowPlayingInfoCenter.default().playbackState.rawValue)")
            #else
            NSLog("%@", "**** Set player state \(playerState)")
            #endif
        }
    }

    private var isInterrupted: Bool = false

    private var timer: Timer?

    // Metadata for the audio item
    private var staticMetadata: NowPlayableStaticMetadata!
    
    var onTimeChange: ((TimeInterval) -> Void)?

    init(player: AVAudioPlayer, title: String, artist: String? = nil) {
        if let shared = ConfigModel.shared {
            self.nowPlayableBehavior = shared.nowPlayableBehavior
        } else {
            self.nowPlayableBehavior = ConfigModel(nowPlayableBehavior: MacNowPlayableBehavior()).nowPlayableBehavior
        }
        
        load(player: player, title: title, artist: artist)
    }
    
    func itemChanged(title: String, artist: String? = nil) {
//        self.title = title
//        self.artist = artist
        
        guard let url = player.url else { return }
        staticMetadata = NowPlayableStaticMetadata(assetURL: url, mediaType: .audio, isLiveStream: false, title: title, artist: artist ?? "", artwork: nil, albumArtist: nil, albumTitle: nil)
        
        configureNowPlayable()
    }

    private func configureNowPlayable() {
        // Configure commands based on your ConfigModel
        var registeredCommands = [] as [NowPlayableCommand]
        var enabledCommands = [] as [NowPlayableCommand]

        for group in ConfigModel.shared.commandCollections {
            registeredCommands.append(contentsOf: group.commands.compactMap { $0.shouldRegister ? $0.command : nil })
            enabledCommands.append(contentsOf: group.commands.compactMap { $0.shouldDisable ? $0.command : nil })
        }

        do {
            try nowPlayableBehavior.handleNowPlayableConfiguration(
                commands: registeredCommands,
                disabledCommands: enabledCommands,
                commandHandler: handleCommand(command:event:),
                interruptionHandler: handleInterrupt(with:)
            )
        } catch {
            print("Error configuring NowPlayable: \(error)")
        }
    }

    private func optOut() {
        timer?.invalidate()
        timer = nil
        player.stop()
        playerState = .stopped
        nowPlayableBehavior.handleNowPlayableSessionEnd()
    }
    
    private func load(player: AVAudioPlayer, title: String, artist: String?) {
        self.player = player
//        self.staticMetadata = metadata
        
        itemChanged(title: title, artist: artist)
    }
    
    func swap(player: AVAudioPlayer, title: String, artist: String? = nil) {
        optOut()
        load(player: player, title: title, artist: artist)
    }

    // MARK: Now Playing Info

    private func handlePlayerItemChange() {
        guard playerState != .stopped else { return }
        nowPlayableBehavior.handleNowPlayableItemChange(metadata: staticMetadata)
    }

    private func handlePlaybackChange() {
        guard playerState != .stopped else { return }

        let isPlaying = playerState == .playing
        let metadata = NowPlayableDynamicMetadata(
            rate: player.rate,
            position: Float(player.currentTime),
            duration: Float(player.duration),
            currentLanguageOptions: [], // Update with actual language options if needed
            availableLanguageOptionGroups: [] // Update with actual language options if needed
        )

        nowPlayableBehavior.handleNowPlayablePlaybackChange(playing: isPlaying, metadata: metadata)
        onTimeChange?(player.currentTime)
    }
    
//    func play() {
//        play()
//    }

    // MARK: Playback Control

    func play() {
        switch playerState {
        case .stopped:
            playerState = .playing
            player.play()
            handlePlayerItemChange()
            startPlaybackUpdates()
        case .playing:
            player.play()
            handlePlayerItemChange()
            startPlaybackUpdates()
        case .paused where isInterrupted:
            playerState = .playing
        case .paused:
            playerState = .playing
            player.play()
        }
    }

    func pause() {
        switch playerState {
        case .stopped:
            break
        case .playing where isInterrupted:
            playerState = .paused
        case .playing:
            playerState = .paused
            player.pause()
        case .paused:
            break
        }
    }

    private func togglePlayPause() {
        switch playerState {
        case .stopped:
            play()
        case .playing:
            pause()
        case .paused:
            play()
        }
    }

    // Implement other playback control methods (nextTrack, previousTrack, seek, etc.)
    // These will likely need to be adapted to work with AVAudioPlayer
    // instead of AVQueuePlayer, as AVAudioPlayer doesn't support features
    // like multiple items or seeking within a track

    private func startPlaybackUpdates() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.handlePlaybackChange()
            self?.objectWillChange.send()
        }
    }

    // MARK: Remote Commands

    private func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch command {
        case .pause:
            pause()
        case .play:
            play()
        case .stop:
            optOut()
        case .togglePausePlay:
            togglePlayPause()
            
        // Handle other commands like nextTrack, previousTrack, seek, etc.
        // You'll need to adapt these to work with AVAudioPlayer's capabilities

        case .changePlaybackRate:
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            setPlaybackRate(event.playbackRate)

        case .skipBackward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            skipBackward(interval: event.interval)
            
        case .skipForward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            skipForward(interval: event.interval)
        // ... (handle other commands as needed)
        /*case .nextTrack:
            skipForward(interval: 15)
        case .previousTrack:
            skipBackward(interval: 15)*/

        default:
            break
        }

        return .success
    }
    
    func skipBackward(interval: TimeInterval) {
        player.currentTime -= interval
    }
    
    func skipForward(interval: TimeInterval) {
        player.currentTime += interval
    }

    func setPlaybackRate(_ rate: Float) {
//        if case .stopped = playerState { return }
        player.rate = rate
    }

    // ... (Implement didEnableLanguageOption and didDisableLanguageOption if needed for your app)

    // MARK: Interruptions

    private func handleInterrupt(with interruption: NowPlayableInterruption) {
        switch interruption {
        case .began:
            isInterrupted = true
        case .ended(let shouldPlay):
            isInterrupted = false

            switch playerState {
            case .stopped:
                break
            case .playing where shouldPlay:
                player.play()
            case .playing:
                playerState = .paused
            case .paused:
                break
            }

        case .failed(let error):
            print(error.localizedDescription)
            optOut()
        }
    }
}

/*
class MacNowPlayable: NowPlayable {
    var defaultAllowsExternalPlayback: Bool = true
    
    var defaultRegisteredCommands: [NowPlayableCommand] = []
    
    var defaultDisabledCommands: [NowPlayableCommand] = []
    
    func handleNowPlayableConfiguration(commands: [NowPlayableCommand], disabledCommands: [NowPlayableCommand], commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus, interruptionHandler: @escaping (NowPlayableInterruption) -> Void) throws {
        print("handleNowPlayableConfiguration called...")
    }
    
    func handleNowPlayableSessionStart() throws {
        print("handleNowPlayableSessionStart called...")
    }
    
    func handleNowPlayableSessionEnd() {
        print("handleNowPlayableSessionEnd called...")
    }
    
    func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata) {
        print("handleNowPlayableItemChange called...")
    }
    
    func handleNowPlayablePlaybackChange(playing: Bool, metadata: NowPlayableDynamicMetadata) {
        print("handleNowPlayablePlaybackChange called...")
    }
    
    
}*/
