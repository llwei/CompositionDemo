//
//  LWVideoPlayer.swift
//  LWVideoPlayer
//
//  Created by lailingwei on 16/6/1.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation

private var LWVideoPlayerItemStatusContext = "LWVideoPlayerItemStatusContext"
private var LWVideoPlayerItemLoadedTimeRangesContext = "LWVideoPlayerItemLoadedTimeRangesContext"

typealias LoadingFailedHandler = ((error: NSError?) -> Void)
typealias PlaybackHandler = ((readyToPlay: Bool, current: Float64, loadedBuffer: Float64, totalBuffer: Float64, finished: Bool) -> Void)


class LWVideoPlayer: NSObject {
    
    // MARK: Properties
    
    private var player: AVPlayer? = AVPlayer()
    private var playerLayer: LWVideoPlayerView?
    
    private var currentProgressObserver: AnyObject?
    
    private var repeatCount: UInt = 0
    private var composable: Bool = true
    private var readyToPlay: Bool = false
    
    private var current: Float64 = 0
    private var loadedBuffer: Float64 = 0
    private var totalBuffer: Float64 = 0
    
    private var loadingFailedHandler: LoadingFailedHandler?
    private var playbackHandler: PlaybackHandler?
    
    
    // MARK:  Life cycle
    
    override init() {
        super.init()
    }
    
    deinit {
        removeObservers()
        print("LWVideoPlayer.deinit")
    }
    
    
    // MARK:  Helper methods
    
    private func setupPlayback(ofPlayerItem item: AVPlayerItem?, withKeys keys: [String], videoPlayerView: LWVideoPlayerView) {
        guard let asset = item?.asset else { return }
        
        // Check whether the values of each of the keys we need has been successfully loaded
        for key in keys {
            var error: NSError?
            if asset.statusOfValueForKey(key, error: &error) == .Failed {
                loadingFailedHandler?(error: error)
                return
            }
        }
        
        if !asset.playable {
            // Asset canot be played.
            let error = LWVideoPlayerError.error(Code.ItemNotPlayable, failureReason: "Asset canot be played")
            loadingFailedHandler?(error: error)
            return
        }
        
        // Asset canot be used to create a composition(e.g. it may have protected content).
        self.composable = asset.composable
        
        // Set up an AVPlayerLayer
        if asset.tracksWithMediaType(AVMediaTypeVideo).count > 0 {
            videoPlayerView.player = player
            playerLayer = videoPlayerView
        }
        
        // Create a new AVPlayerItem and make it the player's current item.
        player?.replaceCurrentItemWithPlayerItem(item)
        
        // Add rate and status/loadedTimeRanges observers
        addObservers()
    }
    
    
    private func resetProgressParameters() {
        current = 0
        loadedBuffer = 0
        totalBuffer = 0
    }
    
    
    // MARK:  Observers
    
    private func addObservers() {
        guard let player = player else { return }
        player.addObserver(self,
                    forKeyPath: "currentItem.status",
                    options: .New,
                    context: &LWVideoPlayerItemStatusContext)
        
        player.addObserver(self,
                    forKeyPath: "currentItem.loadedTimeRanges",
                    options: .New,
                    context: &LWVideoPlayerItemLoadedTimeRangesContext)
        
        // Update "current"
        currentProgressObserver = player.addPeriodicTimeObserverForInterval(CMTimeMake(1, 1),
                                                                             queue: dispatch_get_main_queue(),
                                                                             usingBlock: {
                                                                                [unowned self] (time: CMTime) in
                                                                                
                                                                                self.current = CMTimeGetSeconds(time)
                                                                                self.playbackHandler?(readyToPlay: self.readyToPlay,
                                                                                                    current: self.current,
                                                                                                    loadedBuffer: self.loadedBuffer,
                                                                                                    totalBuffer: self.totalBuffer,
                                                                                                    finished: false)
        })
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(LWVideoPlayer.plackbackFinished(_:)),
                                                         name: AVPlayerItemDidPlayToEndTimeNotification,
                                                         object: player.currentItem)
    }
    
    private func removeObservers() {
        
        if let _ = player?.currentItem {
            player?.removeObserver(self,
                                   forKeyPath: "currentItem.status",
                                   context: &LWVideoPlayerItemStatusContext)
            
            player?.removeObserver(self,
                                   forKeyPath: "currentItem.loadedTimeRanges",
                                   context: &LWVideoPlayerItemLoadedTimeRangesContext)
            
            player?.replaceCurrentItemWithPlayerItem(nil)
        }

        if let observer = currentProgressObserver {
            player?.removeTimeObserver(observer)
            currentProgressObserver = nil
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func observeValueForKeyPath(keyPath: String?,
                                         ofObject object: AnyObject?,
                                                  change: [String : AnyObject]?,
                                                  context: UnsafeMutablePointer<Void>) {
        
        if context == &LWVideoPlayerItemStatusContext {
            if let status = change?[NSKeyValueChangeNewKey]?.integerValue {
                switch status {
                case AVPlayerItemStatus.ReadyToPlay.rawValue:
                    readyToPlay = true
                    // Update "totalBuffer"
                    if let item = player?.currentItem {
                        totalBuffer = CMTimeGetSeconds(item.duration)
                    }
                case AVPlayerItemStatus.Failed.rawValue:
                    readyToPlay = false
                    loadingFailedHandler?(error: player?.currentItem?.error)
                default:
                    readyToPlay = false
                    break
                }
                playbackHandler?(readyToPlay: readyToPlay,
                                 current: current,
                                 loadedBuffer: loadedBuffer,
                                 totalBuffer: totalBuffer,
                                 finished: false)
            }
            
        } else if context == &LWVideoPlayerItemLoadedTimeRangesContext {
            // Update "loadedBuffer"
            if let item = player?.currentItem {
                if let timeRange = item.loadedTimeRanges.first?.CMTimeRangeValue {
                    let startSeconds = CMTimeGetSeconds(timeRange.start)
                    let durationSeconds = CMTimeGetSeconds(timeRange.duration)
                    
                    loadedBuffer = startSeconds + durationSeconds
                    playbackHandler?(readyToPlay: readyToPlay,
                                     current: current,
                                     loadedBuffer: loadedBuffer,
                                     totalBuffer: totalBuffer,
                                     finished: false)
                }
            }
        
        } else {
            super.observeValueForKeyPath(keyPath,
                                         ofObject: object,
                                         change: change,
                                         context: context)
        }
    }
    
    func plackbackFinished(notification: NSNotification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        guard item == player?.currentItem else { return }
        
        if repeatCount == 0 {
            playbackHandler?(readyToPlay: readyToPlay,
                             current: current,
                             loadedBuffer: loadedBuffer,
                             totalBuffer: totalBuffer,
                             finished: true)
        } else {
            repeatCount -= 1
            item.seekToTime(kCMTimeZero)
            current = 0
            player?.play()
        }
    }

}

// MARK: - Public methods

extension LWVideoPlayer {
    
    /**
     Replaces the player's current item with the specified player item.
     
     - parameter item:                 The AVPlayerItem that will become the player's current item.
     - parameter videoPlayerView:      An instance of AVPlayerLayer to display the visual output of the specified AVPlayer
     - parameter count:                Repeat play count
     - parameter loadingFailedHandler: loadingFailedHandler
     - parameter playbackHandler:      playbackHandler
     */
    func replaceCurrentItemWithPlayerItem(item: AVPlayerItem,
                                          videoPlayerView: LWVideoPlayerView,
                                          playRepeatCount count: UInt,
                                                          loadingFailedHandler: LoadingFailedHandler?,
                                                          playbackHandler: PlaybackHandler?) {
        
        // Stop player
        stop()
        
        guard item.status != .Failed else {
            self.loadingFailedHandler?(error: item.error)
            return
        }
        
        // Record repeatCount
        repeatCount = count
        
        // Update input asset, and load the values of AVAsset keys to inspect subsequently
        let assetKeysToLoadAndTest = ["playable", "composable", "tracks", "duration"]
        item.asset.loadValuesAsynchronouslyForKeys(assetKeysToLoadAndTest) {
            [unowned self] in
            dispatch_async(dispatch_get_main_queue(), { 
                self.setupPlayback(ofPlayerItem: item, withKeys: assetKeysToLoadAndTest, videoPlayerView: videoPlayerView)
            })
        }
        
        // Set up handlers
        self.loadingFailedHandler = loadingFailedHandler
        self.playbackHandler = playbackHandler
    }
    
    
    func stop() {
        // Remove old observers
        removeObservers()
        
        // Reset progress parameters
        resetProgressParameters()
        
        // Set up old playerLayer.play to nil
        if let playerLayer = playerLayer {
            playerLayer.player = nil
        }
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func playing() -> Bool {
        return  player?.rate == 1.0 ? true : false
    }
    
    func seekToProgress(progress: Float, completionHandler: ((Bool) -> Void)?) {
        guard let item = player?.currentItem else { return }
        guard 0 <= progress && progress <= 1 else { return }
        
        let secondes = CMTimeGetSeconds(item.duration) * Float64(progress)
        let time = CMTimeMakeWithSeconds(secondes, item.duration.timescale)
        
        player?.seekToTime(time, completionHandler: { (flag: Bool) in
            completionHandler?(flag)
        })
    }
    
    func assetCanComposabled() -> Bool {
        return composable
    }
    
}



// MARK: - ============ LWVideoPlayerView ============

class LWVideoPlayerView: UIView {
    
    override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
    
    var player: AVPlayer? {
        set {
            let playerLayer = layer as! AVPlayerLayer
            playerLayer.player = newValue
        }
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.player
        }
    }
    
    var videoGravity: String {
        set {
            let playerLayer = layer as! AVPlayerLayer
            playerLayer.videoGravity = newValue
        }
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.videoGravity
        }
    }
    
    var readyForDisplay: Bool {
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.readyForDisplay
        }
    }
    
    @available(iOS 7.0, *)
    var videoRect: CGRect {
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.videoRect
        }
    }

    @available(iOS 9.0, *)
    var pixelBufferAttributes: [String : AnyObject]? {
        set {
            let playerLayer = layer as! AVPlayerLayer
            playerLayer.pixelBufferAttributes = newValue
        }
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.pixelBufferAttributes
        }
    }
    
}


// MARK: - ============ LWVideoPlayerError ============

enum Code: Int {
    case ItemNotPlayable    = -1001
}

struct LWVideoPlayerError {
    
    static let Domain = "com.lwvideoplayer.error"
    
    static func error(code: Code, failureReason: String?) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : failureReason ?? ""]
        return NSError(domain: Domain, code: code.rawValue, userInfo: userInfo)
    }
}

