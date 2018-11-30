//
//  AmuseViewController.swift
//  BabyDriver
//
//  Created by 岩澤 忠恭 on 2018/11/30.
//  Copyright © 2018年 岩澤 忠恭. All rights reserved.
//

import UIKit
import AVFoundation
import youtube_ios_player_helper

class AmuseViewController: UIViewController {
    
    @IBOutlet weak var player: YTPlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        player.delegate = self;
        
        let playerVars = ["modestbranding" : 0,
                          "controls" : 1 ,
                          "autoplay" : 1,
                          "playsinline" : 1,
                          "autohide" : 1,
                          "showinfo" : 0
        ]
        
        do {
            try AVAudioSession.sharedInstance()
            .setCategory(AVAudioSession.Category.playback,
                         mode: AVAudioSession.Mode.spokenAudio)
        } catch {
        }
        player.load(withVideoId: "KH394UCULKw", playerVars: playerVars)
    }
}

extension AmuseViewController: YTPlayerViewDelegate {
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        
        
        playerView.playVideo()
    }
}
