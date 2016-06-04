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
    private let filterTitiles = ["filter1", "filter2", "filter3", "filter4", "filter5"]
    private let musicTitles = ["Sunny Jim", "Two On A Bike", "Waldeck", "Whisting"]
    
    private var filterLayer: CALayer = CALayer()
    private var waterLayer: CALayer?
    
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    }
    
    
    
    private func composeMV(index: Int) {
        player.stop()
        waterLayer?.removeFromSuperlayer()
        
        
        if index == 0 {
            // 无
            filterLayer.removeFromSuperlayer()
            let assets = MVFilter.fetchOriginalMovie()
            let mix = LWMediaEditor.mergeMedias(withVideos: assets,
                                                audioAssets: [],
                                                renderSize: CGSize(width: 480, height: 480))
            if let asset = mix.0 {
                let playerItem = AVPlayerItem(asset: asset)
                
                player.replaceCurrentItemWithPlayerItem(playerItem,
                                                        videoPlayerView: preview,
                                                        playRepeatCount: 100,
                                                        loadingFailedHandler: { (error) in
                                                            print(error?.localizedDescription)
                    }, playbackHandler: { (readyToPlay, current, loadedBuffer, totalBuffer, finished) in
                        if readyToPlay {
                            print(current)
                        }
                })
            }
            
        } else if index == 1 {
            // Smile
            let samile = Smile()
            
            if let asset = samile.composition {
                let playerItem = AVPlayerItem(asset: asset)
                if let videoComposition = samile.videoComposition {
                    playerItem.videoComposition = videoComposition
                }
                
                player.replaceCurrentItemWithPlayerItem(playerItem,
                                                        videoPlayerView: preview,
                                                        playRepeatCount: 100,
                                                        loadingFailedHandler: { (error) in
                                                            print(error?.localizedDescription)
                    }, playbackHandler: { (readyToPlay, current, loadedBuffer, totalBuffer, finished) in
                        if readyToPlay {
                            print(current)
                        }
                })
            }
            
        } else if index == 2 {
            // Sakura
            let sakura = Sakura()
            
            if let asset = sakura.composition {
                let playerItem = AVPlayerItem(asset: asset)
                if let videoComposition = sakura.videoComposition {
                    playerItem.videoComposition = videoComposition
                }
                
                player.replaceCurrentItemWithPlayerItem(playerItem,
                                                        videoPlayerView: preview,
                                                        playRepeatCount: 100,
                                                        loadingFailedHandler: { (error) in
                                                            print(error?.localizedDescription)
                    }, playbackHandler: { (readyToPlay, current, loadedBuffer, totalBuffer, finished) in
                        if readyToPlay {
                            print(current)
                        }
                })
            }
        }
        
        // 水印
        let width = UIScreen.mainScreen().bounds.size.width
        let overlayLayer = MVFilter.fetchOverlayLayer(CGSize(width: width, height: width))
        preview.layer.addSublayer(overlayLayer)
        waterLayer = overlayLayer
        
        player.play()
    }
    
    
    private func composeFilter(index: Int) {
        
        filterLayer.contents = UIImage(named: filterTitiles[index] + ".png")?.CGImage
        filterLayer.frame = preview.layer.bounds
        preview.layer.addSublayer(filterLayer)
        
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
