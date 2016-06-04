//
//  Smile.swift
//  LWMediaEditor
//
//  Created by lailingwei on 16/6/4.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation

class Smile: MVFilter {

    override init() {
        super.init()
        let objs = MVFilter.fetchOriginalMovie()
        let time = CMTimeAdd(objs[0].asset.duration, objs[1].asset.duration)
        var assets = [LWVideoAsset]()
        
        
        let asset3 = AVAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("smile_light", ofType: "mp4")!))
        let smilelight = LWVideoAsset(asset: asset3,
                                      insertTimeRange: CMTimeRangeMake(kCMTimeZero, time),
                                      atTime: kCMTimeZero,
                                      audioEnable: false)
        smilelight.setOpacity(0.2, atTime: kCMTimeZero)
        assets.append(smilelight)
        
        let asset4 = AVAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("smile_text", ofType: "mp4")!))
        let smileText = LWVideoAsset(asset: asset4,
                                     insertTimeRange: CMTimeRangeMake(kCMTimeZero, time),
                                     atTime: kCMTimeZero,
                                     audioEnable: false)
        smileText.setOpacity(0.2, atTime: kCMTimeZero)
        assets.append(smileText)
        assets.appendContentsOf(objs)
        
        
        
        let mix = LWMediaEditor.mergeMedias(withVideos: assets,
                                            audioAssets: [],
                                            renderSize: CGSize(width: 480, height: 480))
        
        composition = mix.0
        videoComposition = mix.1
        audioMix = mix.2
    }
    
}
