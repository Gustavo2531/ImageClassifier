//
//  ViewController.swift
//  ImageClass
//
//  Created by Gustavo Méndez on 11/6/18.
//  Copyright © 2018 Gustavo Méndez. All rights reserved.
//

import UIKit
import AssetsLibrary
import Photos


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //l
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var rolloBoton: UIButton!
    @IBOutlet weak var camaraBoton: UIButton!
    @IBOutlet weak var mybutton: UIButton!
    var image:UIImage!
    let model = GoogLeNetPlaces()
    let model2 = Resnet50()
    let arrayImages = [UIImage(named: "forest"), UIImage(named: "grassland"),  UIImage(named: "mountains"),
                        UIImage(named: "ocean"), UIImage(named: "desert")]
    var index = 4
     let imagePickerController = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        mybutton.titleLabel?.minimumScaleFactor = 0.5
        mybutton.titleLabel?.numberOfLines = 0
        mybutton.titleLabel?.adjustsFontSizeToFitWidth = true
        imagePickerController.delegate = self
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera){
            camaraBoton.isHidden = false
            //            rolloBoton.isHidden = false
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateDisplay()
    }
    @IBAction func album() {
        PHPhotoLibrary.requestAuthorization{(status) in
            switch status{
            case .authorized:
                let picker = UIImagePickerController()
                picker.allowsEditing = true
                picker.delegate = self
                picker.sourceType = UIImagePickerController.SourceType.photoLibrary
                self.present(picker, animated: true)
                break
            case .notDetermined:
                break
            case .restricted:
                break
            case .denied:
                break
            }
        }
       
    }
    
    @IBAction func camara(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
        if (sender == camaraBoton) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        present(picker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            resizeImage(image2: image)
            
        }
        //imageView.image = image
        //resizeImage(image2: image)
        picker.dismiss(animated: true, completion: nil)
    }
   
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func updateDisplay(){
        //resizeImage(image2: image)
        imageView.image = self.image
        
    }
    func resizeImage(image2: UIImage){
        let newSize = CGSize(width: 224.0, height: 224.0)
        UIGraphicsBeginImageContext(newSize)
        image2.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.imageView.image = self.image
        
    }
    @IBAction func loadImageAction(_ sender: UIButton){
        self.index = (self.index >= self.arrayImages.count - 1 ) ? 0 : self.index+1
        image = self.arrayImages[self.index]
        resizeImage(image2: image)
        
        //imageView.image = arrayImages[self.index]
    }
    func convertImageToPixelBuffer() -> CVPixelBuffer?{
        guard let image2 = self.image else {return nil}
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image2.size.width),  Int(image2.size.height), kCVPixelFormatType_32ARGB, nil, &pixelBuffer)
        if status != kCVReturnSuccess {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width:  Int(image2.size.width), height:  Int(image2.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image2.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        UIGraphicsPushContext(context!)
        image2.draw(in: CGRect(x: 0.0, y: 0.0, width:  image2.size.width, height:  image2.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    @IBAction func predictAction(_send: UIButton){
        if let pixelBuffer = self.convertImageToPixelBuffer(){
            do{
               
                  let sceneLabel =  try model2.prediction(image:  pixelBuffer)//try model.prediction(sceneImage: pixelBuffer)
                    resultsLabel.text = sceneLabel.classLabel
            }catch{
                resultsLabel.text = "Could Not Predict image"
                
            }
        
         
            
        }else{
            resultsLabel.text = "Could Not Convert image to pixel buffer"
        }
    }
}

