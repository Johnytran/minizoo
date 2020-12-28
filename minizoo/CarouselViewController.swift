//
//  CarouselViewController.swift
//  firstARtemplate
//
//  Created by Owner on 25/4/20.
//  Copyright © 2020 admin. All rights reserved.
//

import UIKit
import Firebase
import SwiftGifOrigin

class CarouselViewController: UIViewController {

    @IBOutlet weak var iCarouselView: iCarousel!
    @IBOutlet weak var animalListCarousel: iCarousel!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingImageView: UIImageView!
    var animalArr = [Animal]();
    var currentAnimal: Animal?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iCarouselView.type = .rotary;
        iCarouselView.contentMode = .scaleAspectFill;
        //assignbackground();
        view.layer.contents = #imageLiteral(resourceName: "home_bg").cgImage
        // Do any additional setup after loading the view.
        
        // show loading view
        loadingImageView.image = UIImage.gif(name: "loading")
        
        // get animal data from firebase
        self.fetchAnimal();
    }
    func fetchAnimal(){
        var ref: DatabaseReference!

        ref = Database.database().reference()
        let animalsRef = ref.child("animals").queryOrderedByKey();
        animalsRef.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let animalObj = Animal();
                
                //print(self.animalArr);
                let animal = snap.value as! [String: Any]
                let title = animal["title"] as! String
                let name = animal["name"] as! String
                let avatar = animal["avatar"] as! String
                let aname = animal["aname"] as! String
                let scn = animal["scn"] as! String
                
                
                animalObj.title = title;
                animalObj.name = name;
                animalObj.scn = scn;
                animalObj.avatar = avatar;
                animalObj.aname = aname;
                
                var materials: [Material] = []
                for link in snap.childSnapshot(forPath: "materials").children{
                    let snapLink = link as! DataSnapshot
                    let matObj = Material();
                    
                    let mat = snapLink.value as! [String: Any]
                    let name = mat["name"] as! String;
                    let link = mat["link"] as! String;
                    
                    matObj.name = name;
                    matObj.link = link;
                    
                    //print(name);
                    materials.append(matObj);
                }
                animalObj.material = materials;
                
                // initial for scale
                var scale: [Float] = []
                let snapScaleX: Float = (snap.childSnapshot(forPath: "scale/x").value as? NSNumber)?.floatValue ?? 0.0;
                let snapScaleY: Float = (snap.childSnapshot(forPath: "scale/y").value as? NSNumber)?.floatValue ?? 0.0;
                let snapScaleZ: Float = (snap.childSnapshot(forPath: "scale/z").value as? NSNumber)?.floatValue ?? 0.0;
                
                scale.append(snapScaleX);
                scale.append(snapScaleY);
                scale.append(snapScaleZ);
                animalObj.scale = scale;
                
                // initial for position
                var postion: [Float] = []
                let snapPosX: Float = (snap.childSnapshot(forPath: "position/x").value as? NSNumber)?.floatValue ?? 0.0;
                let snapPosY: Float = (snap.childSnapshot(forPath: "position/y").value as? NSNumber)?.floatValue ?? 0.0;
                let snapPosZ: Float = (snap.childSnapshot(forPath: "position/z").value as? NSNumber)?.floatValue ?? 0.0;
                
                postion.append(snapPosX);
                postion.append(snapPosY);
                postion.append(snapPosZ);
                animalObj.postion = postion;
                
                
                self.animalArr.append(animalObj);
                
                self.animalListCarousel.reloadData();
                self.loadingImageView.isHidden = true;
                self.loadingLabel.isHidden = true;
            }
          // ...
        })
    }
}

extension CarouselViewController: iCarouselDataSource, iCarouselDelegate{
    func numberOfItems(in carousel: iCarousel) -> Int {
        return self.animalArr.count;
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var imageView: UIImageView!
        if view==nil{
            imageView = UIImageView(frame: CGRect(x:0, y:0, width: 200, height: 200));
            imageView.contentMode = .scaleAspectFit;
        }else{
            imageView = view as? UIImageView;
        }
        if(self.animalArr.count>0){
            
            self.loadingImageView.isHidden = false;
            
            let animalObj = self.animalArr[index];
            
            let fileManager = FileManager.default
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig)
            let documentsUrl:URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
            
            let destinationFileUrl = documentsUrl.appendingPathComponent(animalObj.aname)
            
            if (fileManager.fileExists(atPath: destinationFileUrl.path)){
                // file exist
                let avatarData = try? Data(contentsOf: destinationFileUrl) ;
                imageView.image = UIImage.gif(data: avatarData!);
                self.loadingImageView.isHidden = true;
                print("file exist");
            }else{
                // file not exist
                let request = URLRequest(url:URL(string: animalObj.avatar)!)
                   
                let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                   if let tempLocalUrl = tempLocalUrl, error == nil {
                       // Success
                       if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                            print("Successfully avatar downloaded. Status code: \(statusCode)")
                            
                       }
                       
                       do {
                           try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                            print("file not exist");
                            let avatarData = try? Data(contentsOf: destinationFileUrl) ;
                            imageView.image = UIImage.gif(data: avatarData!);
                            self.loadingImageView.isHidden = true;
                       } catch (let writeError) {
                           print("Error creating a file \(destinationFileUrl) : \(writeError)")
                       }
                       
                   } else {
                    print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
                   }
                }
                task.resume()
            }
            
            imageView.clipsToBounds = true;
        }
        return imageView;
    }
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        
        
        if(self.animalArr.count>0){
            let animalObj = self.animalArr[index];
            self.currentAnimal = animalObj;
        }
        self.performSegue(withIdentifier: "showAnimal", sender: self)
        
        //print(index);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showAnimal") {
            let detailController = segue.destination as! UINavigationController
            let animalVC = detailController.viewControllers.first as! ViewController
            animalVC.currentAnimal = self.currentAnimal;
        }
    }
}
