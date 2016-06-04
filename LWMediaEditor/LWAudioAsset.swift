//
//  LWAudioAsset.swift
//  LWMediaEditor
//
//  Created by lailingwei on 16/6/3.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation


// MARK: - LWAudioAsset

class LWAudioAsset: NSObject {

    let asset: AVAsset
    let timeRange: CMTimeRange
    let atTime: CMTime
    
    private var _audioMixInputParameters = [LWAudioMixInputParameter]()
    var audioMixInputParameters: [LWAudioMixInputParameter] {
        get {
            return _audioMixInputParameters
        }
    }
    
    
    // MARK: Initial
    
    init(asset: AVAsset,
         insertTimeRange timeRange: CMTimeRange,
                         atTime: CMTime) {
        
        self.asset = asset
        self.timeRange = timeRange
        self.atTime = atTime

    }
    
     // MARK: AudioMixInputParameters
    
    func setVolume(volume: Float, atTime time: CMTime) {
        let audioMixInputParameter = LWAudioMixInputParameter(typeVolumeAtTimeWithVolume: volume, atTime: atTime)
        _audioMixInputParameters.append(audioMixInputParameter)
    }
    
    func setVolumeRampFromStartVolume(startVolume: Float, toEndVolume endVolume: Float, timeRange: CMTimeRange) {
        let audioMixInputParameter = LWAudioMixInputParameter(typeVolumeAtTimeRangeWithStartVolume: startVolume,
                                                              endVolume: endVolume,
                                                              timeRange: timeRange)
        _audioMixInputParameters.append(audioMixInputParameter)
    }
    
}


// MARK: - LWAudioMixInputParameter

enum LWAudioMixInputParametersType {
    case VolumeAtTime
    case VolumeAtTimeRange
}


class LWAudioMixInputParameter: NSObject {
    
    let type: LWAudioMixInputParametersType 
    
    private var volume: Float = 1.0
    private var atTime: CMTime = kCMTimeZero
    
    private var startVolume: Float = 1.0
    private var endVolume: Float = 1.0
    private var timeRange: CMTimeRange = kCMTimeRangeZero
    
    
    // MARK:  Initial
    
    init(typeVolumeAtTimeWithVolume volume: Float, atTime: CMTime) {
        self.type = .VolumeAtTime
        self.volume = volume
        self.atTime = atTime
    }
    
    init(typeVolumeAtTimeRangeWithStartVolume startVolume: Float,
                                                 endVolume: Float,
                                                 timeRange: CMTimeRange) {
        self.type = .VolumeAtTimeRange
        self.startVolume = startVolume
        self.endVolume = endVolume
        self.timeRange = timeRange
    }
    
    // MARK: Fetch parameters
    
    func fetchParamtersForTypeVolumeAtTime() -> (Float, CMTime)? {
        guard type == .VolumeAtTime else { return nil }
        return (volume, atTime)
    }
    
    func fetchParamtersForTypeVolumeAtTimeRange() -> (Float, Float, CMTimeRange)? {
        guard type == .VolumeAtTimeRange else { return nil }
        return (startVolume, endVolume, timeRange)
    }
    
}

