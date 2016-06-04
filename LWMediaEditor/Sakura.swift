//
//  Sakura.swift
//  LWMediaEditor
//
//  Created by lailingwei on 16/6/4.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation

class Sakura: MVFilter {
    
    override init() {
        super.init()
        let objs = MVFilter.fetchOriginalMovie()
        let time = CMTimeAdd(objs[0].asset.duration, objs[1].asset.duration)
        
        let asset3 = AVAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("sakura", ofType: "mp4")!))
        let sakuraAsset = LWVideoAsset(asset: asset3,
                                       insertTimeRange: CMTimeRangeMake(kCMTimeZero, time),
                                       atTime: kCMTimeZero,
                                       audioEnable: false)
        sakuraAsset.setOpacity(0.3, atTime: kCMTimeZero)
        
        var assets = [LWVideoAsset]()
        assets.append(sakuraAsset)
        assets.appendContentsOf(objs)
        
        let mix = LWMediaEditor.mergeMedias(withVideos: assets,
                                            audioAssets: [],
                                            renderSize: CGSize(width: 480, height: 480))
        
        composition = mix.0
        videoComposition = mix.1
        audioMix = mix.2
    }
    
}
