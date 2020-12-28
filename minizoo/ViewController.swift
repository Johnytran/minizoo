//
//  ViewController.swift
//  firstARtemplate
//
//  Created by admin on 29/7/19.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

extension float4x4 {
    var translation: SIMD3<Float> {
        let translation = self.columns.3
        return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
}
extension SCNNode {
    
    convenience init(named name: String) {
        self.init()
        
        guard let scene = SCNScene(named: name) else {
            return
        }
        
        for childNode in scene.rootNode.childNodes {
            addChildNode(childNode)
        }
    }
    
}

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var object: SCNNode!
    var currentAngleY: Float = 0.0
    var currentAnimal: Animal?
    var loadingScene: SCNScene!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if((self.currentAnimal) != nil){
            
            
            // Set the view's delegate
            self.sceneView.delegate = self
            // Allow user to manipulate camera
            sceneView.allowsCameraControl = true
            // Allow user translate image
            sceneView.cameraControlConfiguration.allowsTranslation = false
            
            
            
            ///local file test
//            self.object = SCNNode(named: "art.scnassets/parrot.scn");
//
//            let scene = SCNScene()
//
//
//            for child in scene.rootNode.childNodes {
//              object.addChildNode(child)
//            }
//
//
//            self.sceneView.scene = scene
//            // Add the node to the scene
//            sceneView.scene.rootNode.addChildNode(object)
            
            ///end local file test
            
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)));
            self.sceneView.isUserInteractionEnabled = true;
            self.sceneView.addGestureRecognizer(tapGesture);

            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.didPinch(_:)))
            self.sceneView.addGestureRecognizer(pinchGesture);

            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))

            self.sceneView.addGestureRecognizer(panGesture)


            self.navigationItem.title = self.currentAnimal?.title;

            self.object = SCNNode();

            self.initModel();
            

            
        }
    }
    
    func addGIF(name: String) -> SCNNode {
        let gifNode = SCNNode()
        let gifPlane = SCNPlane(width: 1, height: 1)
        let gifImage = UIImage.gif(name: name)
        let gifImageView = UIImageView(image: gifImage)
        gifPlane.firstMaterial?.diffuse.contents = gifImageView
        gifNode.geometry = gifPlane
        gifNode.position = SCNVector3(0, -1, -3)
        gifNode.scale = SCNVector3(x: 0.6, y: 0.6, z: 0.6)

        return gifNode
    }
    
    func initModel(){
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        // Create destination URL
        let documentsUrl:URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
        let destinationFileUrl = documentsUrl.appendingPathComponent(self.currentAnimal!.name)
        
        //show preloader
        self.loadingScene = SCNScene()
        sceneView.scene = self.loadingScene
        sceneView.scene.rootNode.addChildNode(addGIF(name: "waiting2"))
        
        //downloading file
        let fileManager = FileManager.default
        if (fileManager.fileExists(atPath: destinationFileUrl.path)){
            print("FILE AVAILABLE")
            //print(documentsUrl);
            let materials:[Material] = self.currentAnimal!.material;
            if(materials.count>0){
                
                var matCount: Int=0;
                for mat in materials{
                    let destinationMatUrl = documentsUrl.appendingPathComponent(mat.name);
                    
                    if (fileManager.fileExists(atPath: destinationMatUrl.path)){
                        // mat exist
                        matCount+=1;
                        if(matCount==materials.count){
                            DispatchQueue.main.async {
                                self.sceneView.scene.rootNode.removeFromParentNode();
                                self.showModel(url: destinationFileUrl, scale: self.currentAnimal!.scale, pos: self.currentAnimal!.postion);
                            }
                        }
                    }else{
                        // mat not exist
                        //download material
                        let materialURL = URL(string: mat.link)
                        if((materialURL) != nil){

                            let request = URLRequest(url:materialURL!)
                               
                            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                               if let tempLocalUrl = tempLocalUrl, error == nil {
                                   // Success
                                   if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                                        print("Successfully material downloaded. Status code: \(statusCode)")
                                        
                                   }
                                   
                                   do {
                                       try FileManager.default.copyItem(at: tempLocalUrl, to: destinationMatUrl)
                                        print(destinationMatUrl);
                                        matCount+=1;
                                        if(matCount==materials.count){
                                            DispatchQueue.main.async {
                                                self.sceneView.scene.rootNode.removeFromParentNode();
                                                self.showModel(url: destinationFileUrl, scale: self.currentAnimal!.scale, pos: self.currentAnimal!.postion);
                                            }
                                        }
                                   } catch (let writeError) {
                                       print("Error creating a file \(destinationFileUrl) : \(writeError)")
                                   }
                                   
                               } else {
                                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
                               }
                            }
                            task.resume()
                        }
                    }// else mat exist
                    
                    
                }
            }
                
                
                
            
         } else {
            // no exist scn file
            let fileURL = URL(string: self.currentAnimal!.scn)
            if((fileURL) != nil){
                
                let request = URLRequest(url:fileURL!)
                   
                let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                   if let tempLocalUrl = tempLocalUrl, error == nil {
                       // Success
                       if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                            print("Successfully downloaded. Status code: \(statusCode)")
                            //object = SCNNode(named: "art.scnassets/"+self.currentAnimal?.scn+".scn");
                       }
                       
                       do {
                           try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                            print(destinationFileUrl);
                            
                            let materials:[Material] = self.currentAnimal!.material;
                            if(materials.count>0){
                                
                                var matCount: Int=0;
                                for mat in materials{
                                    let destinationMatUrl = documentsUrl.appendingPathComponent(mat.name);
                                    
                                    if (fileManager.fileExists(atPath: destinationMatUrl.path)){
                                        // mat exist
                                        matCount+=1;
                                        if(matCount==materials.count){
                                            DispatchQueue.main.async {
                                                self.sceneView.scene.rootNode.removeFromParentNode();
                                                self.showModel(url: destinationFileUrl, scale: self.currentAnimal!.scale, pos: self.currentAnimal!.postion);
                                            }
                                        }
                                    }else{
                                        // mat not exist
                                        //download material
                                        let materialURL = URL(string: mat.link)
                                        if((materialURL) != nil){

                                            let request = URLRequest(url:materialURL!)
                                               
                                            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                                               if let tempLocalUrl = tempLocalUrl, error == nil {
                                                   // Success
                                                   if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                                                        print("Successfully material downloaded. Status code: \(statusCode)")
                                                        
                                                   }
                                                   
                                                   do {
                                                       try FileManager.default.copyItem(at: tempLocalUrl, to: destinationMatUrl)
                                                        print(destinationMatUrl);
                                                        matCount+=1;
                                                        if(matCount==materials.count){
                                                            DispatchQueue.main.async {
                                                                self.sceneView.scene.rootNode.removeFromParentNode();
                                                                self.showModel(url: destinationFileUrl, scale: self.currentAnimal!.scale, pos: self.currentAnimal!.postion);
                                                            }
                                                        }
                                                   } catch (let writeError) {
                                                       print("Error creating a file \(destinationFileUrl) : \(writeError)")
                                                   }
                                                   
                                               } else {
                                                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
                                               }
                                            }
                                            task.resume()
                                        }
                                    }// else mat exist
                                    
                                    
                                }
                            }
                                
                            
                        
                       } catch (let writeError) {
                           print("Error creating a file \(destinationFileUrl) : \(writeError)")
                       }
                       
                   } else {
                    print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
                   }
                }
                task.resume()
            }
             print("FILE NOT AVAILABLE")
         }
    }
    func modelShadow(){
        let flourPlane = SCNFloor()
        let groundPlane = SCNNode()
        let groundMaterial = SCNMaterial()
        groundMaterial.lightingModel = .constant
        groundMaterial.writesToDepthBuffer = true
        groundMaterial.colorBufferWriteMask = SCNColorMask.alpha
        groundMaterial.isDoubleSided = true
        flourPlane.materials = [groundMaterial]
        groundPlane.geometry = flourPlane
        
        self.object.addChildNode(groundPlane)
        
        // Create a ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.shadowMode = .deferred
        ambientLight.light?.color = UIColor.white
        ambientLight.light?.type = SCNLight.LightType.ambient
        ambientLight.position = SCNVector3(x: 0,y: 5,z: 0)
        
        // Create a directional light node with shadow
        let myNode = SCNNode()
        myNode.light = SCNLight()
        myNode.light?.type = SCNLight.LightType.directional
        myNode.light?.color = UIColor.white
        myNode.light?.castsShadow = true
        myNode.light?.automaticallyAdjustsShadowProjection = true
        myNode.light?.shadowSampleCount = 64
        myNode.light?.shadowRadius = 16
        myNode.light?.shadowMode = .deferred
        myNode.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        myNode.light?.shadowColor = UIColor.black.withAlphaComponent(0.75)
        myNode.position = SCNVector3(x: 0,y: 5,z: 0)
        myNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        
        // Add the lights to the container
        self.object.addChildNode(ambientLight)
        self.object.addChildNode(myNode)
    }
    func showModel(url: URL, scale: [Float], pos: [Float]){
        //print(url);
        
        let scene = SCNScene()
        self.sceneView.scene = scene
        do{
            // Load the character in the idle animation
            let idleScene = try SCNScene(url: url, options: nil)

            // Add all the child nodes to the parent node
            for child in idleScene.rootNode.childNodes {
              object.addChildNode(child)
            }
        }catch{}
        
        
        // Set up some properties
        //object.position = SCNVector3(0, -1.5, -3)
        //object.scale = SCNVector3(0.1, 0.1, 0.1)
        
        object.position = SCNVector3(pos[0], pos[1], pos[2])
        object.scale = SCNVector3(scale[0], scale[1], scale[2])
        
        
        //show shadow
        modelShadow();
        
//        self.object.position = SCNVector3(x: 0, y: -1, z: -1);
//        self.object.scale = SCNVector3(x: 4, y: 4, z: 4)
        
        // Add the node to the scene
        sceneView.scene.rootNode.addChildNode(object)
        
        
    }
    @objc
    func didPan(_ gesture: UIPanGestureRecognizer) {
        guard let _ = object else { return }
        let translation = gesture.translation(in: gesture.view)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
        
        newAngleY += currentAngleY
        object?.eulerAngles.y = newAngleY
        
        if gesture.state == .ended{
            currentAngleY = newAngleY
        }
    }
    @objc
    func didPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let _ = object else { return }
        var originalScale = object?.scale
        
        switch gesture.state {
        case .began:
            originalScale = object?.scale
            gesture.scale = CGFloat((object?.scale.x)!)
        case .changed:
            guard var newScale = originalScale else { return }
            if gesture.scale < 0.5{ newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5) }else if gesture.scale > 2{
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            object?.scale = newScale
        case .ended:
            guard var newScale = originalScale else { return }
            if gesture.scale < 0.5{ newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5) }else if gesture.scale > 2{
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            object?.scale = newScale
            gesture.scale = CGFloat((object?.scale.x)!)
        default:
            gesture.scale = 1.0
            originalScale = nil
        }
    }
    
    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        guard let _ = self.object else { return }
        
        let tapLocation = gesture.location(in: sceneView)
        let results = sceneView.hitTest(tapLocation, types: .featurePoint)
        
        if let result = results.first {
            let translation = result.worldTransform.translation
            self.object.position = SCNVector3Make(translation.x, translation.y, translation.z);
            self.object.scale = SCNVector3(0.2, 0.2, 0.2);
            
            //print(object);
            self.sceneView.scene.rootNode.addChildNode(self.object)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    
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
