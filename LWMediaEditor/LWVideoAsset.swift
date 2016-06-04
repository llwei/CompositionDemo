//
//  LWVideoAsset.swift
//  LWMediaEditor
//
//  Created by lailingwei on 16/6/3.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - LWVideoAsset

class LWVideoAsset: NSObject {

    let asset: AVAsset
    let timeRange: CMTimeRange
    let atTime: CMTime
    let audioEnable: Bool
    
    private var _layerInstructions = [LWVideoCompositionLayerInstruction]()
    var layerInstructions: [LWVideoCompositionLayerInstruction] {
        get {
            return _layerInstructions
        }
    }
    
    // MARK: Initial
    
    init(asset: AVAsset,
         insertTimeRange timeRange: CMTimeRange,
                         atTime: CMTime,
                         audioEnable: Bool) {
        
        self.asset = asset
        self.timeRange = timeRange
        self.atTime = atTime
        self.audioEnable = audioEnable
    }
    
    
    // MARK: VideoCompositionLayerInstruction
    
    func setTransform(transform: CGAffineTransform, atTime time: CMTime) {
        let layerInstruction = LWVideoCompositionLayerInstruction(typeTransformAtTimeWithTransform: transform,
                                                                  atTime: time)
        _layerInstructions.append(layerInstruction)
    }
    
    func setTransformRampFromStartTransform(startTransform: CGAffineTransform,
                                            toEndTransform endTransform: CGAffineTransform,
                                                           timeRange: CMTimeRange) {
        let layerInstruction = LWVideoCompositionLayerInstruction(typeTransformAtTimeRangeWithStartTransform: startTransform,
                                                                  endTransform: endTransform,
                                                                  timeRange: timeRange)
        _layerInstructions.append(layerInstruction)
    }
    
    func setOpacity(opacity: Float, atTime time: CMTime) {
        let layerInstruction = LWVideoCompositionLayerInstruction(typeOpacityAtTimeWithOpacity: opacity,
                                                                  atTime: time)
        _layerInstructions.append(layerInstruction)
    }
    
    func setOpacityRampFromStartOpacity(startOpacity: Float,
                                        toEndOpacity endOpacity: Float,
                                                     timeRange: CMTimeRange) {
        let layerInstruction = LWVideoCompositionLayerInstruction(typeOpacityATTimeRangeWithStartOpacity: startOpacity,
                                                                  endOpacity: endOpacity,
                                                                  timeRange: timeRange)
        _layerInstructions.append(layerInstruction)
    }
    
    func setCropRectangle(cropRectangle: CGRect, atTime time: CMTime) {
        let layerInstruction = LWVideoCompositionLayerInstruction(typeCropRectangleAtTimeWithCropRectangle: cropRectangle,
                                                                  atTime: time)
        _layerInstructions.append(layerInstruction)
    }
    
    func setCropRectangleRampFromStartCropRectangle(startCropRectangle: CGRect,
                                                    toEndCropRectangle endCropRectangle: CGRect,
                                                                       timeRange: CMTimeRange) {
        let layerInstruction = LWVideoCompositionLayerInstruction(typeCropRectangleWithStartCropRectangle: startCropRectangle,
                                                                  endCropRectangle: endCropRectangle,
                                                                  timeRange: timeRange)
        _layerInstructions.append(layerInstruction)
    }
    
}


// MARK: - LWVideoCompositionLayerInstruction

enum LWVideoCompositionLayerInstructionType {
    case TransformAtTime
    case TransformATTimeRange
    case OpacityAtTime
    case OpacityATTimeRange
    case CropRectangleAtTime
    case CropRectangleATTimeRange
}


class LWVideoCompositionLayerInstruction: NSObject {
    
    let type: LWVideoCompositionLayerInstructionType
    
    private var transform: CGAffineTransform = CGAffineTransformIdentity
    private var opacity: Float = 1.0
    private var cropRectangle: CGRect = CGRectZero
    private var atTime: CMTime = kCMTimeZero
    
    private var startTransform: CGAffineTransform = CGAffineTransformIdentity
    private var endTransform: CGAffineTransform = CGAffineTransformIdentity
    private var startOpacity: Float = 1.0
    private var endOpacity: Float = 1.0
    private var startCropRectangle: CGRect = CGRectZero
    private var endCropRectangle: CGRect = CGRectZero
    private var timeRange: CMTimeRange = kCMTimeRangeZero
    
    
    // MARK:  Initial
    
    init(typeTransformAtTimeWithTransform transform: CGAffineTransform, atTime: CMTime) {
        self.type = .TransformAtTime
        self.transform = transform
        self.atTime = atTime
    }
    
    init(typeOpacityAtTimeWithOpacity opacity: Float, atTime: CMTime) {
        self.type = .OpacityAtTime
        self.opacity = opacity
        self.atTime = atTime
    }
    
    init(typeCropRectangleAtTimeWithCropRectangle cropRectangle: CGRect, atTime: CMTime) {
        self.type = .CropRectangleAtTime
        self.cropRectangle = cropRectangle
        self.atTime = atTime
    }
    
    init(typeTransformAtTimeRangeWithStartTransform startTransform: CGAffineTransform,
                                                    endTransform: CGAffineTransform,
                                                    timeRange: CMTimeRange) {
        self.type = .TransformATTimeRange
        self.startTransform = startTransform
        self.endTransform = endTransform
        self.timeRange = timeRange
    }
    
    init(typeOpacityATTimeRangeWithStartOpacity startOpacity: Float,
                                                endOpacity: Float,
                                                timeRange: CMTimeRange) {
        self.type = .OpacityATTimeRange
        self.startOpacity = startOpacity
        self.endOpacity = endOpacity
    }
    
    init(typeCropRectangleWithStartCropRectangle startCropRectangle: CGRect,
                                                 endCropRectangle: CGRect,
                                                 timeRange: CMTimeRange) {
        self.type = .CropRectangleATTimeRange
        self.startCropRectangle = startCropRectangle
        self.endCropRectangle = endCropRectangle
    }
    
    
    // MARK: Fetch parameters
    
    func fetchParamtersForTypeTransformAtTime() -> (CGAffineTransform, CMTime)? {
        guard type == .TransformAtTime else { return nil }
        return (transform, atTime)
    }
    
    func fetchParamtersForTypeOpacityAtTime() -> (Float, CMTime)? {
        guard type == .OpacityAtTime else { return nil }
        return (opacity, atTime)
    }
    
    func fetchParamtersForTypeCropRectangleAtTime() -> (CGRect, CMTime)? {
        guard type == .CropRectangleAtTime else { return nil }
        return (cropRectangle, atTime)
    }
    
    func fetchParamtersForTypeTransformAtTimeRange() -> (CGAffineTransform, CGAffineTransform, CMTimeRange)? {
        guard type == .TransformATTimeRange else { return nil }
        return (startTransform, endTransform, timeRange)
    }
    
    func fetchParamtersForTypeOpacityATTimeRange() -> (Float, Float, CMTimeRange)? {
        guard type == .OpacityATTimeRange else { return nil }
        return (startOpacity, endOpacity, timeRange)
    }
    
    func fetchParamtersForTypeCropRectangleATTimeRange() -> (CGRect, CGRect, CMTimeRange)? {
        guard type == .CropRectangleATTimeRange else { return nil }
        return (startCropRectangle, endCropRectangle, timeRange)
    }
    
}

