//
//  VirutalScreen.swift
//  Television
//
//  Created by Walter Nordström on 2017-08-29.
//  Copyright © 2017 Walter Nordström. All rights reserved.
//

import UIKit
import SceneKit
import AVKit
import SpriteKit

public class VirtualScreen: SCNNode {
    
    var moveScreenTranslationTransform: simd_float4x4?
    var videoPlayer: AVPlayer
    
    init(_ videoPlayer: AVPlayer) {
        
        self.videoPlayer = videoPlayer
        super.init()        
        
        let skScenewidth: CGFloat = 1276.0 / 2.0
        let skSceneHeight: CGFloat = 712.0 / 2.0
        
        let spriteKitScene = SKScene(size: CGSize(width: skScenewidth, height: skSceneHeight))
        
        let videoSKNode = SKVideoNode(avPlayer: videoPlayer);
        //        videoSKNode.size = spriteKitScene.size
        videoSKNode.size = CGSize(width: skScenewidth - 20.0, height: skSceneHeight - 20.0)
        videoSKNode.play()
        videoSKNode.yScale = -1;
        videoSKNode.position = CGPoint(x: spriteKitScene.size.width / 2.0, y: spriteKitScene.size.height / 2.0)
        spriteKitScene.addChild(videoSKNode)
        
        let imagePlane = SCNPlane(width: 1.280 / 2, height: 0.720 / 2)
        imagePlane.firstMaterial?.isDoubleSided = true
        //        imagePlane.firstMaterial?.lightingModel = .constant
        imagePlane.firstMaterial?.diffuse.contents = spriteKitScene
        
        self.geometry = imagePlane
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startScreenMovement(realtiveTo transform: simd_float4x4) {
        moveScreenTranslationTransform = matrix_multiply(transform.inverse, simdTransform)
    }
    
}
