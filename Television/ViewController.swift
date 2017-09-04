//
//  ViewController.swift
//  Television
//
//  Created by Walter Nordström on 2017-08-28.
//  Copyright © 2017 Walter Nordström. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var addScreenButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    private var refreshTimer: Timer?
    private var screens = [VirtualScreen]()
    
    private var videoURLQueue: Queue<String>!
    
    let videoURLs = [
        "http://bcliveuniv-lh.akamaihd.net/i/news_1@194050/master.m3u8",
        "http://content.jwplatform.com/manifests/vM7nH0Kl.m3u8",
        "http://voa-lh.akamaihd.net/i/voa_mpls_tvmc6@320298/master.m3u8",
        "https://cdn-videos.akamaized.net/btv/zixi/fastly/europe/live/primary.m3u8",
        "http://d383mxeq7zv96c.cloudfront.net/api/ott/getVideoStream/USNATIONAL/master.m3u8?country=us",
        "https://edge.free-speech-tv-live.top.comcast.net/out/u/fstv.m3u8",
        "http://cdnapi.kaltura.com/p/931702/sp/93170200/playManifest/entryId/1_oorxcge2/format/applehttp/protocol/http/uiConfId/28428751/a.m3u8"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        videoURLQueue = Queue<String>(fromList: videoURLs)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.handlePinch(gestureRecognize:)))
        view.addGestureRecognizer(pinchGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    private func startSession() {
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
    }
    
    @objc
    func handlePinch(gestureRecognize: UIPinchGestureRecognizer) {
        
        guard gestureRecognize.numberOfTouches == 2 else { return }
        
        let a = gestureRecognize.location(ofTouch: 0, in: sceneView)
        let b = gestureRecognize.location(ofTouch: 1, in: sceneView)
        let midpoint = CGPoint(x: (a.x + b.x)/2, y: (a.y + b.y)/2)
        
        if let screen = virtualScreen(at: midpoint) {
            let scale = Float(gestureRecognize.scale)
            screen.scale = SCNVector3(screen.scale.x * scale, screen.scale.y * scale, screen.scale.z * scale)
            gestureRecognize.scale = 1.0
        }
        
    }
    
    @objc
    func handleTap(gestureRecognize: UITapGestureRecognizer) {
        
        let position = gestureRecognize.location(ofTouch: 0, in: sceneView)
        
        if let screen = virtualScreen(at: position) {
            
            silenceAllScreens()
            screen.videoPlayer.volume = 1.0
        }
    }
    
    private func silenceAllScreens() {
        screens.forEach { $0.videoPlayer.volume = 0.0 }
    }
    
    @IBAction func resetButtonPressed(_ sender: UIButton) {
        
        resetTimer()
        screens.forEach { $0.removeFromParentNode() }
        screens.removeAll()
        startSession()
    }
    
    
    @IBAction func addScreenButtonPressed(_ sender: UIButton) {
        addScreen()
    }
    
    func addScreen() {
        
        guard let currentFrame = self.sceneView.session.currentFrame else { return }
        
        silenceAllScreens()
        
        // Setup video player
        let urlString = videoURLQueue.dequeue()!
        let url = URL(string: urlString)!
        let playerItem = AVPlayerItem(url: url)
        let videoPlayer = AVPlayer(playerItem: playerItem)
        
        // Create a plane node and add it to the scene
        let screen = VirtualScreen(videoPlayer)
        self.sceneView.scene.rootNode.addChildNode(screen)
        screens.append(screen)
        
        // Set transform of node to be 1m in front of camera
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1.0
        screen.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
    }
    
    // MARK: - Gesture Recognizers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard touches.count == 1 else { return }
        guard let currentFrame = self.sceneView.session.currentFrame else { return }
        guard let location = touches.first?.location(in: sceneView) else { return }
        
        if let screen = virtualScreen(at: location) {
            if let _ = refreshTimer { return } // timer active
            
            let c = currentFrame.camera.transform.columns.3
            let s = screen.simdPosition
            
            
            let distance = sqrt(pow(c.x-s.x,2) + pow(c.y-s.y,2) + pow(c.z-s.z,2))
            
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -distance
            
            let scale = screen.scale
            
            SCNTransaction.animationDuration = 0.1
            screen.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
            screen.scale = scale
            
            screen.startScreenMovement(realtiveTo: currentFrame.camera.transform)
            // Refresh the current gesture at 60 Hz - This ensures smooth updates even when no
            // new touch events are incoming (but the camera might have moved).
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.016_667, repeats: true, block: { _ in
                self.updatePositionFor(screen)
            })
        }
       
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetTimer()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetTimer()
    }
    
    private func resetTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func updatePositionFor(_ screen: VirtualScreen) {
        
        guard let currentFrame = self.sceneView.session.currentFrame else {
            return
        }
        
        screen.simdTransform = matrix_multiply(currentFrame.camera.transform, screen.moveScreenTranslationTransform!)
        
    }
    
    /// Hit tests against the `sceneView` to find an object at the provided point.
    func virtualScreen(at point: CGPoint) -> VirtualScreen?  {
        let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
        let hitTestResults: [SCNHitTestResult] = sceneView.hitTest(point, options: hitTestOptions)
        
        return hitTestResults.lazy.flatMap { result in
            self.isNodePartOfVirtualScreen(result.node)
            }.first
    }
    
    func isNodePartOfVirtualScreen(_ node: SCNNode) -> VirtualScreen? {
        if let virtualScreen = node as? VirtualScreen {
            return virtualScreen
        }
        
        if node.parent != nil {
            return isNodePartOfVirtualScreen(node.parent!)
        }
        
        return nil
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
