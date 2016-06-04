//
//  TableViewController.swift
//  LWMediaEditor
//
//  Created by lailingwei on 16/6/3.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class TableViewController: UITableViewController {

    private var firstAsset: LWVideoAsset?
    private var secondAsset: LWVideoAsset?
    private var audioAsset: LWAudioAsset?
    
    private var audioPlayer: AVAudioPlayer?
    private var moviePath: String?
    
    @IBOutlet weak var activityMonitor: UIActivityIndicatorView!
    
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activeAudioSession()
    }
    
    private func activeAudioSession() {
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            let nserror = error as NSError
            print(nserror.localizedDescription)
        }
        do {
            try audioSession.setActive(true)
        } catch {
            let nserror = error as NSError
            print(nserror.localizedDescription)
        }
    }
    
    deinit {
        print("TableViewController.deinit")
    }
    
    
    // MARK: - Target actions

    private func loadVideoOne() {
        guard let videoFirstPath = NSBundle.mainBundle().pathForResource("video2", ofType: "mp4") else { return }
        
        let url = NSURL(fileURLWithPath: videoFirstPath)
        let moviePlayerController = MPMoviePlayerViewController(contentURL: url)
        presentMoviePlayerViewControllerAnimated(moviePlayerController)
        
        let asset = AVAsset(URL: url)
        firstAsset = LWVideoAsset(asset: asset,
                                  insertTimeRange: CMTimeRangeMake(kCMTimeZero,
                                    asset.duration),
                                  atTime: kCMTimeZero,
                                  audioEnable: false)
        firstAsset?.setOpacity(0.0, atTime: asset.duration)
    }
    
    private func loadVideoTwo() {
        guard let videoSecontPath = NSBundle.mainBundle().pathForResource("video4", ofType: "mp4") else { return }
        
        let url = NSURL(fileURLWithPath: videoSecontPath)
        let moviePlayerController = MPMoviePlayerViewController(contentURL: url)
        presentMoviePlayerViewControllerAnimated(moviePlayerController)
        
        if let firstAsset = firstAsset {
            let asset = AVAsset(URL: url)
            secondAsset = LWVideoAsset(asset: asset,
                                      insertTimeRange: CMTimeRangeMake(kCMTimeZero,
                                        asset.duration),
                                      atTime: firstAsset.asset.duration,
                                      audioEnable: false)
        }
        
    }
    
    private func loadAudio() {
        guard let audioPath = NSBundle.mainBundle().pathForResource("Sunny Jim", ofType: "mp3") else { return }
        
        if let audioPlayer = audioPlayer {
            if audioPlayer.playing {
                audioPlayer.stop()
                print("Stop")
            } else {
                audioPlayer.play()
                print("Play")
            }
            
        } else {
            let url  = NSURL(fileURLWithPath: audioPath)
            let asset = AVAsset(URL: url)
            audioAsset = LWAudioAsset(asset: asset, insertTimeRange: CMTimeRangeMake(kCMTimeZero, asset.duration), atTime: kCMTimeZero)
            do {
                let audioPlayer = try AVAudioPlayer(contentsOfURL: url)
                self.audioPlayer = audioPlayer
                if audioPlayer.prepareToPlay() {
                    audioPlayer.play()
                    print("Play")
                }
            } catch {
                let nserror = error as NSError
                print(nserror.localizedDescription)
            }
        }
    }
    
    
    private func compose() {
        
        guard let firstAsset = firstAsset, let secondAsset = secondAsset else { return }
        audioPlayer?.stop()
        
        let mix = LWMediaEditor.mergeMedias(withVideos: [firstAsset, secondAsset], audioAssets: [], renderSize: CGSize(width: 480, height: 480))

        if let mixComposition = mix.0 {
            
            let movieName = NSProcessInfo.processInfo().globallyUniqueString + ".mov"
            let savePath = NSTemporaryDirectory().stringByAppendingString("/" + movieName)
            moviePath = savePath
            let url = NSURL(fileURLWithPath: savePath)
            
            view.userInteractionEnabled = false
            activityMonitor.startAnimating()
            LWMediaEditor.exportAsset(mixComposition,
                                      outputURL: url,
                                      outputFileType: AVFileTypeQuickTimeMovie,
                                      videoComposition: mix.1,
                                      audioMix: mix.2,
                                      completionHandler: { (status, error) in
                                        
                                        self.view.userInteractionEnabled = true
                                        self.activityMonitor.stopAnimating()
                                        if status == .Completed {
                                            let moviePlayerController = MPMoviePlayerViewController(contentURL: url)
                                            self.presentMoviePlayerViewControllerAnimated(moviePlayerController)
                                        } else {
                                            print(status.rawValue)
                                            print(error?.localizedDescription)
                                        }
            })
        }
        
    }
    
    
    // MARK: - UITable view deleagate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            // Load video 1
            loadVideoOne()
            
        case 1:
            // Load video 2
            loadVideoTwo()
            
        case 2:
            // Load audio
            loadAudio()
            
        case 3:
            // Compose
            compose()
            
        default:
            break
        }
    }
   
    
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }

}
