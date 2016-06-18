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

            
        default:
            break
        }
    }
   
    
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }

}
