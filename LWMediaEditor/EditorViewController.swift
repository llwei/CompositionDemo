//
//  EditorViewController.swift
//  LWMediaEditor
//
//  Created by lailingwei on 16/6/3.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation

private let MVCellIdentifier = "MVCell"
private let FilterCellIdentifier = "FilterCell"

class EditorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var preview: LWVideoPlayerView!
    @IBOutlet weak var mvTableView: UITableView!
    @IBOutlet weak var filterTableView: UITableView!
    
    private var player = LWVideoPlayer()
    
    private let mvTitles = ["无", "Smile", "Sakura"]
    private let filterTitiles = ["CIPhotoEffectChrome",
                                 "CIPhotoEffectFade",
                                 "CIPhotoEffectInstant",
                                 "CIPhotoEffectMono",
                                 "CIPhotoEffectNoir",
                                 "CIPhotoEffectProcess",
                                 "CIPhotoEffectTonal"]
    private let musicTitles = ["Sunny Jim", "Two On A Bike", "Waldeck", "Whistling"]
    
    private var filterLayer: CALayer = CALayer()
    private var waterLayer: CALayer?
    
    private var filterIndex: Int = 0
    
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let playerItem = AVPlayerItem(asset: fetchBaseComposeVideoAsset())
        player.replaceCurrentItemWithPlayerItem(playerItem,
                                                videoPlayerView: preview,
                                                playRepeatCount: 100,
                                                loadingFailedHandler: nil,
                                                playbackHandler: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        player.play()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        player.stop()
    }
    
    deinit {
        print("EditorViewController deinit")
    }
    
    
    // MARK: - UITable view delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == mvTableView {
            return mvTitles.count
        } else {
            return filterTitiles.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if tableView == mvTableView {
            let cell = tableView.dequeueReusableCellWithIdentifier(MVCellIdentifier, forIndexPath: indexPath)
            
            cell.textLabel?.text = mvTitles[indexPath.row]
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(FilterCellIdentifier, forIndexPath: indexPath)
            
            cell.textLabel?.text = filterTitiles[indexPath.row]
            
            return cell

        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if tableView == mvTableView {
            composeMV(indexPath.row)
        } else {
            composeFilter(indexPath.row)
        }
        
    }
    
    
    
    // MARK: - Target actions
    
    @IBAction func export(sender: UIBarButtonItem) {
    }
    
    
    @IBAction func changeMusic(sender: UIButton) {
        
        let filter = CIFilter(name: filterTitiles[filterIndex])!
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        for music in musicTitles {
            let url = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(music, ofType: "mp3")!)
            let action = UIAlertAction(title: music,
                                       style: .Default,
                                       handler: { (_) in
                                        
                                        let (composition, audioMix) = self.addAudioTrack(fromVideoAsset: self.fetchBaseComposeVideoAsset(), audioAsset: AVAsset(URL: url))
                                        
                                        let playerItem = AVPlayerItem(asset: composition)
                                        playerItem.videoComposition = self.fetchFilterVideoComposition(filter, videoAsset: self.fetchBaseComposeVideoAsset())
                                        playerItem.audioMix = audioMix
                                        self.player.replaceCurrentItemWithPlayerItem(playerItem,
                                            videoPlayerView: self.preview,
                                            playRepeatCount: 100,
                                            loadingFailedHandler: nil,
                                            playbackHandler: nil)
                                        
                                        self.player.play()
                                        
            })
            actionSheet.addAction(action)
        }
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    
    private func composeMV(index: Int) {
        player.stop()
        
        if index == 0 {
            // 无
            let playerItem = AVPlayerItem(asset: fetchBaseComposeVideoAsset())
            player.replaceCurrentItemWithPlayerItem(playerItem,
                                                    videoPlayerView: preview,
                                                    playRepeatCount: 100,
                                                    loadingFailedHandler: nil,
                                                    playbackHandler: nil)
            
        } else if index == 1 {
            // Smile
        } else if index == 2 {
            // Sakura
        }
        
        player.play()
    }
    
    
    private func composeFilter(index: Int) {
        player.stop()
        
        filterIndex = index
        
        let filterName = filterTitiles[index]
        
        if let filter = CIFilter(name: filterName) {
            let asset = fetchBaseComposeVideoAsset()
            let videoComposition = fetchFilterVideoComposition(filter, videoAsset: asset)
            
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.videoComposition = videoComposition
            
            player.replaceCurrentItemWithPlayerItem(playerItem,
                                                    videoPlayerView: preview,
                                                    playRepeatCount: 100,
                                                    loadingFailedHandler: nil,
                                                    playbackHandler: nil)
            player.play()
        }
    }
    
    
    
    // MARK: - Helper methods
    
    // 根据video2 和 video4 拿到拼接合成后的静音视频资源
    private func fetchBaseComposeVideoAsset() -> AVMutableComposition {
        
        let asset1 = AVAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("video2", ofType: "mp4")!))
        let asset2 = AVAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("video4", ofType: "mp4")!))
        
        let mixComposition = AVMutableComposition()
        
        let videoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                                                                     preferredTrackID: kCMPersistentTrackID_Invalid)
        try! videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset1.duration),
                                        ofTrack: asset1.tracksWithMediaType(AVMediaTypeVideo)[0],
                                        atTime: kCMTimeZero)
        try! videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset2.duration),
                                        ofTrack: asset2.tracksWithMediaType(AVMediaTypeVideo)[0],
                                        atTime: asset1.duration)
        
        return mixComposition
    }
    
    private func addAudioTrack(fromVideoAsset composition: AVMutableComposition, audioAsset: AVAsset) -> (AVMutableComposition, AVMutableAudioMix) {
        
        let composition = composition
        let audioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio,
                                                                  preferredTrackID: kCMPersistentTrackID_Invalid)
        try! audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, composition.duration),
                                        ofTrack: audioAsset.tracksWithMediaType(AVMediaTypeAudio)[0],
                                        atTime: kCMTimeZero)
        
        
        let audioParameters = AVMutableAudioMixInputParameters(track: audioTrack)
        audioParameters.setVolume(0.8, atTime: kCMTimeZero)
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = [audioParameters]
        
        return (composition, audioMix)
    }
    
    
    private func fetchFilterVideoComposition(filter: CIFilter, videoAsset: AVAsset) -> AVMutableVideoComposition {
        return AVMutableVideoComposition(asset: videoAsset,
                                         applyingCIFiltersWithHandler: { (request) in
                                            
                                            let source = request.sourceImage.imageByClampingToExtent()
                                            filter.setValue(source, forKey: kCIInputImageKey)
                                            let output = filter.outputImage!.imageByCroppingToRect(request.sourceImage.extent)
                                            request.finishWithImage(output, context: nil)
        })
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
