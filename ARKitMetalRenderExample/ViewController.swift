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
    
    fileprivate let virtualNode = VirtualObjectNode()

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
        print("\(self.classForCoder)/" + #function)
        
        for child in virtualNode.childNodes {
            if let material = child.geometry?.firstMaterial {
                material.diffuse.contents = UIColor.black
            }
        }
        virtualNode.scale = SCNVector3Make(2, 2, 2)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(self.virtualNode)
        })
    }

}

extension SCNNode {
    
    func loadDuck() {
        guard let scene = SCNScene(named: "duck.scn", inDirectory: "models.scnassets/duck") else {fatalError()}
        for child in scene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            addChildNode(child)
        }
    }
}

class VirtualObjectNode: SCNNode {
    
    override init() {
        super.init()
        loadDuck()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

