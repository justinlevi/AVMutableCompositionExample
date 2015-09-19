//
//  ViewController.swift
//  AVMutableCompositionTest
//
//  Created by Justin Winter on 9/18/15.
//  Copyright © 2015 wintercreative. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

  var player = AVPlayer()
  var playerLayer = AVPlayerLayer()
  
  var asset: AVAsset = {
    let path = NSBundle.mainBundle().pathForResource("hubblecast", ofType: "m4v")
    let url = NSURL(fileURLWithPath: path!)
    return AVAsset(URL: url)
  }()
  
  var currentTime: Double {
    get { return CMTimeGetSeconds(player.currentTime()) }
    set { player.seekToTime(CMTimeMakeWithSeconds(newValue, 1), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) }
  }

  var duration: Double {
    guard let currentItem = player.currentItem else { return 0.0 }
    return CMTimeGetSeconds(currentItem.duration)
  }

  @IBOutlet weak var toolBar: UIToolbar!
  @IBOutlet var v: UIView!
  
  @IBAction func playPauseButtonWasPressed(sender: UIBarButtonItem) {
    if player.rate != 1.0 {
      if currentTime == duration {
        // At end, so got back to begining.
        currentTime = 0.0
      }
      player.play()
    }
    else {
      player.pause()
    }
    
    var barButtonItems = toolBar.items!
    barButtonItems[0] = UIBarButtonItem(barButtonSystemItem: player.rate == 1.0 ? .Pause : .Play,
      target: self, action: "playPauseButtonWasPressed:")
    toolBar.setItems(barButtonItems, animated: true)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let mutableComposition = AVMutableComposition()
    
    let type = AVMediaTypeVideo
    let prefTrackID = kCMPersistentTrackID_Invalid
    
    let sourceVideoAssetTrack: AVAssetTrack = asset.tracksWithMediaType(type).first!
    
    let videoCompositionTrack1 = mutableComposition.addMutableTrackWithMediaType(type, preferredTrackID: prefTrackID)
    let videoCompositionTrack2 = mutableComposition.addMutableTrackWithMediaType(type, preferredTrackID: prefTrackID)
    
    // TRACK 1 : Starting from the beginning, take 5 seconds of the source video and add this to track 1 at the beginning
    do {
      let startTime = kCMTimeZero // must be multiple of 10
      let duration = CMTimeMakeWithSeconds(10,600)
      let range = CMTimeRangeMake(startTime, duration)
      try videoCompositionTrack1.insertTimeRange(range, ofTrack: sourceVideoAssetTrack, atTime: kCMTimeZero)
    }catch { print(error) }
    
    
    // TRACK 2 : Starting at 10 seconds, Take 5 seconds of the source video and add this to track 2 starting at 5 seconds
    do {
      let startTime = CMTimeMakeWithSeconds(10,600) // must be multiple of 10
      let duration = CMTimeMakeWithSeconds(10,600)
      let range = CMTimeRangeMake(startTime, duration)
      try videoCompositionTrack2.insertTimeRange(range, ofTrack: sourceVideoAssetTrack, atTime: CMTimeMakeWithSeconds(3, 600))
    }catch { print(error) }
    
    
    let instruction = AVMutableVideoCompositionInstruction()
    let timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(3, 600), CMTimeMakeWithSeconds(1, 600))
    let fromLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack1)
    fromLayer.setOpacityRampFromStartOpacity(1, toEndOpacity: 0, timeRange: timeRange)
    let toLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack2)
    
    instruction.layerInstructions = [fromLayer, toLayer]
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, mutableComposition.duration)
    
    let videoComposition = AVMutableVideoComposition(propertiesOfAsset: mutableComposition)
    videoComposition.instructions = [instruction]
    videoComposition.frameDuration = CMTimeMake(1, 60)
    
    
    let playerItem = AVPlayerItem(asset: mutableComposition)
    playerItem.videoComposition = videoComposition
    
    player = AVPlayer(playerItem: playerItem)
    playerLayer = AVPlayerLayer(player: player)
    playerLayer.frame = v.frame
    v.layer.addSublayer(playerLayer)
    
  }

}

