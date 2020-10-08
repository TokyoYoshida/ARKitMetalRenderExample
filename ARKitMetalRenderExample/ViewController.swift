//
//  ViewController.swift
//  ARKitMetalRenderExample
//
//  Created by TokyoYoshida on 2020/10/07.
//  Copyright © 2020 TokyoMac. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Metal
import MetalKit

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var metalView: MetalOverlayView!
    
//    fileprivate let virtualNode = VirtualObjectNode()

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()

        startRunning()
    }

    fileprivate func startRunning() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    var isRendering = false
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else {return}
        let pixelBuffer = frame.capturedImage

        if isRendering {
            return
        }
        isRendering = true
        
        DispatchQueue.main.async(execute: {
            let orientation = UIApplication.shared.statusBarOrientation
            let viewportSize = self.sceneView.bounds.size
            
            var image = CIImage(cvPixelBuffer: pixelBuffer)
            
            let transform = frame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
            image = image.transformed(by: transform)
            
            let context = CIContext(options:nil)
            guard let cameraImage = context.createCGImage(image, from: image.extent) else {return}

            guard let snapshotImage = self.sceneView.snapshot().cgImage else {return}

            self.metalView.registerTexturesFor(cameraImage: cameraImage, snapshotImage: snapshotImage)
            
            self.metalView.time = Float(time)
            
            self.isRendering = false
        })
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        addBubble(node: node)
    }
    
    func addBubble(node: SCNNode) {
        let sphereNode = SCNNode()

        sphereNode.geometry = SCNSphere(radius: 0.05)
        sphereNode.position.y += Float(0.05)
        if let material = sphereNode.geometry?.firstMaterial {
            material.diffuse.contents = UIColor.black
            material.lightingModel = .lambert
        }

        node.addChildNode(sphereNode)

        node.runAction(SCNAction.repeatForever(SCNAction.move(by: SCNVector3(0, 0.1, 0), duration: 5)))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let touchPos = touch.location(in: sceneView)
        let hitTest = sceneView.hitTest(touchPos, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            let anchor = ARAnchor(transform: hitTest.first!.worldTransform)
            sceneView.session.add(anchor: anchor)
        }
    }
}
