//
//  MVFilter.swift
//  LWMediaEditor
//
//  Created by lailingwei on 16/6/4.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation

class MVFilter: NSObject {

    var composition: AVMutableComposition?
    var videoComposition: AVMutableVideoComposition?
    var audioMix: AVMutableAudioMix?
    
    
    static func fetchOriginalMovie() -> [LWVideoAsset] {
        var objs = [LWVideoAsset]()
        let videoFirstPath = NSBundle.mainBundle().pathForResource("video2", ofType: "mp4")!
        let asset1 = AVAsset(URL: NSURL(fileURLWithPath: videoFirstPath))
        let firstAsset = LWVideoAsset(asset: asset1,
                                      insertTimeRange: CMTimeRangeMake(kCMTimeZero, asset1.duration),
                                      atTime: kCMTimeZero,
                                      audioEnable: false)
        firstAsset.setOpacity(0.0, atTime: asset1.duration)
        objs.append(firstAsset)
        
        let videoSecontPath = NSBundle.mainBundle().pathForResource("video4", ofType: "mp4")!
        let url = NSURL(fileURLWithPath: videoSecontPath)
        let asset2 = AVAsset(URL: url)
        let secondAsset = LWVideoAsset(asset: asset2,
                                       insertTimeRange: CMTimeRangeMake(kCMTimeZero, asset2.duration),
                                       atTime: firstAsset.asset.duration,
                                       audioEnable: false)
        objs.append(secondAsset)
        return objs
    }
    
    // MARK: - Helper methods
    
    static func fetchOverlayLayer(size: CGSize) -> CALayer {
        let subtitleText = CATextLayer()
        subtitleText.string = "lailingwei"
        subtitleText.font = "Helvetica-Bold"
        subtitleText.fontSize = 26
        subtitleText.frame = CGRect(x: 0, y: 0, width: size.width, height: 50)
        subtitleText.alignmentMode = kCAAlignmentCenter
        subtitleText.foregroundColor = UIColor.groupTableViewBackgroundColor().CGColor
        
        
        let starImage = UIImage(named: "star")
        let startLayer = CALayer()
        startLayer.contents = starImage?.CGImage
        startLayer.frame = CGRect(x: 50, y: 50, width: 30, height: 30)
        startLayer.masksToBounds = true
        // Rotate
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 2.0
        animation.repeatCount = 5
        animation.autoreverses = true
        animation.fromValue = 0.0;
        animation.toValue = 2.0 * M_PI
        startLayer.addAnimation(animation, forKey: "rotaion1")
        
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        overlayLayer.masksToBounds = true
        overlayLayer.addSublayer(startLayer)
        overlayLayer.addSublayer(subtitleText)
        
        return overlayLayer
    }
    
    
    static func videoBorderAnimationTool(size: CGSize) -> AVVideoCompositionCoreAnimationTool {
        
        let overlayLayer = fetchOverlayLayer(size)
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        return AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
    }
}
