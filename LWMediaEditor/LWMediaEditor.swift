//
//  LWMediaEditor.swift
//  LWMediaEditor
//
//  Created by lailingwei on 16/6/3.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation

typealias ExportCompletionHandler = ((status: AVAssetExportSessionStatus, error: NSError?) -> Void)


class LWMediaEditor: NSObject {

    static let shareInstance = LWMediaEditor()
    
    
    // MARK: - Public methods
    
    static func mergeMedias(withVideos videoAssets: [LWVideoAsset],
                                       audioAssets: [LWAudioAsset],
                                       renderSize: CGSize) -> (AVMutableComposition?, AVMutableVideoComposition?, AVMutableAudioMix?) {
        
        guard videoAssets.count > 0 || audioAssets.count > 0 else { return (nil, nil, nil) }
        
        // AVMutableComposition
        let mixComposition = AVMutableComposition()
        
        // ======== Videos =======
        var layerInstructions = [AVVideoCompositionLayerInstruction]()
        var timeRange: CMTimeRange = kCMTimeRangeZero
        for videoAsset in videoAssets {
            if let videoTrack = LWMediaEditor.addMutableVideoTrack(mixComposition, videoAsset: videoAsset) {
                let videoCompositionLayerInstruction = LWMediaEditor.videoCompositionLayerInstruction(videoTrack, videoAsset: videoAsset)
                layerInstructions.append(videoCompositionLayerInstruction)
                
                timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(timeRange.duration, videoAsset.asset.duration))
            }
            let _ = LWMediaEditor.addMutableAudioTrack(mixComposition, videoAsset: videoAsset)
        }
        
        // AVMutableVideoCompositionInstruction
        let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
        videoCompositionInstruction.timeRange = timeRange
        videoCompositionInstruction.layerInstructions = layerInstructions
        videoCompositionInstruction.backgroundColor = UIColor.clearColor().CGColor
        
        // AVMutableVideoComposition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [videoCompositionInstruction]
        videoComposition.frameDuration = CMTimeMake(1, 30)
        videoComposition.renderSize = renderSize
        
        
        // ======== Audios =======
        var inputParameters = [AVAudioMixInputParameters]()
        for audioAsset in audioAssets {
            if let audioTrack = LWMediaEditor.addMutableAudioTrack(mixComposition, audioAsset: audioAsset) {
                let inputParameter = LWMediaEditor.audioMixInputParameters(audioTrack, audioAsset: audioAsset)
                inputParameters.append(inputParameter)
            }
        }
        
        // AVMutableAudioMix
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = inputParameters
        
        return (mixComposition, videoComposition, audioMix)
    }
    
    
    static func exportAsset(asset: AVAsset,
                            outputURL: NSURL,
                            outputFileType: String,
                            videoComposition: AVVideoComposition?,
                            audioMix: AVAudioMix?,
                            completionHandler: ExportCompletionHandler?) {
    
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            print("Initial AVAssetExportSession error!")
            return
        }
        
        exporter.shouldOptimizeForNetworkUse = true
        exporter.outputURL = outputURL
        exporter.outputFileType = outputFileType
        exporter.videoComposition = videoComposition
        exporter.audioMix = audioMix
        
        exporter.exportAsynchronouslyWithCompletionHandler { 
            dispatch_async(dispatch_get_main_queue(), { 
                completionHandler?(status: exporter.status, error: exporter.error)
            })
        }
    }
    
    
    // MARK: - Helper methods for Videos
    
    private static func addMutableVideoTrack(mixComposition: AVMutableComposition,
                                             videoAsset: LWVideoAsset) -> AVMutableCompositionTrack? {
        guard let videoTrack = videoAsset.asset.tracksWithMediaType(AVMediaTypeVideo).first else {
            print("add video track failed")
            return nil
        }
        
        let track = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try track.insertTimeRange(videoAsset.timeRange,
                                      ofTrack: videoTrack,
                                      atTime: videoAsset.atTime)
            return track
        } catch {
            let nserror = error as NSError
            print("Failed to load video track: \(videoAsset), error: \(nserror.localizedDescription)")
            return nil
        }
    }
    
    private static func addMutableAudioTrack(mixComposition: AVMutableComposition,
                                             videoAsset: LWVideoAsset) -> AVMutableCompositionTrack? {
        guard let audioTrack = videoAsset.asset.tracksWithMediaType(AVMediaTypeAudio).first where videoAsset.audioEnable else {
            print("add audio track failed")
            return nil
        }
        
        let track = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try track.insertTimeRange(videoAsset.timeRange,
                                      ofTrack: audioTrack,
                                      atTime: videoAsset.atTime)
            return track
        } catch {
            let nserror = error as NSError
            print("Failed to load audio track: \(videoAsset), error: \(nserror.localizedDescription)")
            return nil
        }
    }
    
    private static func videoCompositionLayerInstruction(assetTrack: AVAssetTrack,
                                                         videoAsset: LWVideoAsset) -> AVMutableVideoCompositionLayerInstruction {
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
        
        for layerInstructionModel in videoAsset.layerInstructions {
            switch layerInstructionModel.type {
            case .TransformAtTime:
                if let (transform, atTime) = layerInstructionModel.fetchParamtersForTypeTransformAtTime() {
                    layerInstruction.setTransform(transform, atTime: atTime)
                }
            case .TransformATTimeRange:
                if let (startTransform, endTransform, timeRange) = layerInstructionModel.fetchParamtersForTypeTransformAtTimeRange() {
                    layerInstruction.setTransformRampFromStartTransform(startTransform,
                                                                        toEndTransform: endTransform,
                                                                        timeRange: timeRange)
                }
            case .OpacityAtTime:
                if let (opacity, atTime) = layerInstructionModel.fetchParamtersForTypeOpacityAtTime() {
                    layerInstruction.setOpacity(opacity, atTime: atTime)
                }
            case .OpacityATTimeRange:
                if let (startOpacity, endOpacity, timeRange) = layerInstructionModel.fetchParamtersForTypeOpacityATTimeRange() {
                    layerInstruction.setOpacityRampFromStartOpacity(startOpacity,
                                                                    toEndOpacity: endOpacity,
                                                                    timeRange: timeRange)
                }
            case .CropRectangleAtTime:
                if let (cropRectangle, atTime) = layerInstructionModel.fetchParamtersForTypeCropRectangleAtTime() {
                    layerInstruction.setCropRectangle(cropRectangle, atTime: atTime)
                }
            case .CropRectangleATTimeRange:
                if let (startCropRectangle, endCropRectangle, timeRange) = layerInstructionModel.fetchParamtersForTypeCropRectangleATTimeRange() {
                    layerInstruction.setCropRectangleRampFromStartCropRectangle(startCropRectangle,
                                                                                toEndCropRectangle: endCropRectangle,
                                                                                timeRange: timeRange)
                }
            }
        }
        
        return layerInstruction
    }
    
    
    // MARK: - Helper methods for audios
    
    private static func addMutableAudioTrack(mixComposition: AVMutableComposition,
                                             audioAsset: LWAudioAsset) -> AVMutableCompositionTrack? {
        guard let audioTrack = audioAsset.asset.tracksWithMediaType(AVMediaTypeAudio).first else {
            print("add audioMix track failed")
            return nil
        }
        
        let track = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try track.insertTimeRange(audioAsset.timeRange,
                                      ofTrack: audioTrack,
                                      atTime: audioAsset.atTime)
            return track
        } catch {
            let nserror = error as NSError
            print("Failed to load audio track: \(audioAsset), error: \(nserror.localizedDescription)")
            return nil
        }
    }
 
    private static func audioMixInputParameters(track: AVAssetTrack,
                                                audioAsset: LWAudioAsset) -> AVMutableAudioMixInputParameters {
        
        let audioMixInputParameters = AVMutableAudioMixInputParameters(track: track)
        
        for audioMixInputParameterModel in audioAsset.audioMixInputParameters {
            switch audioMixInputParameterModel.type {
            case .VolumeAtTime:
                if let (volume, atTime) = audioMixInputParameterModel.fetchParamtersForTypeVolumeAtTime() {
                    audioMixInputParameters.setVolume(volume, atTime: atTime)
                }
            case .VolumeAtTimeRange:
                if let (startVolume, endVolume, timeRange) = audioMixInputParameterModel.fetchParamtersForTypeVolumeAtTimeRange() {
                    audioMixInputParameters.setVolumeRampFromStartVolume(startVolume,
                                                                         toEndVolume: endVolume,
                                                                         timeRange: timeRange)
                }
            }
        }
        
        return audioMixInputParameters
    }
    
}
