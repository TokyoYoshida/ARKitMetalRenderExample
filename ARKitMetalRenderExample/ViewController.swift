//
//  ViewController.swift
//  ARKitMetalRenderExample
//
//  Created by TokyoYoshida on 2020/10/07.
//  Copyright © 2020 TokyoMac. All rights reserved.
//

import UIKit
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)
    }
}
