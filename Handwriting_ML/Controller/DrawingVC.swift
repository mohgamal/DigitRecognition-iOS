//
//  ViewController.swift
//  Handwriting_ML
//
//  Created by Mohammed Abd El-Aty on 23/12/2017.
//  Copyright © 2017 Artistic Solvents. All rights reserved.
//

import UIKit
import CoreML
import Vision

class DrawingVC: UIViewController {

    @IBOutlet weak var predictionLbl: UILabel!
    @IBOutlet weak var drawingImageView: UIImageView!
    
    var lastPoint = CGPoint.zero
    var swiped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        drawingImageView.image = nil
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: drawingImageView)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first{
            let currentPoint = touch.location(in: drawingImageView)
            drawLine(fromPoint: lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if swiped == false {
            drawLine(fromPoint: lastPoint, toPoint: lastPoint)
        }
    }
    
    func drawLine(fromPoint: CGPoint, toPoint: CGPoint){
        UIGraphicsBeginImageContext(drawingImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        drawingImageView.image?.draw(in: CGRect(x: 0, y: 0, width: drawingImageView.frame.size.width, height: drawingImageView.frame.size.height))
        
        context?.move(to: CGPoint(x: fromPoint.x,y: fromPoint.y))
        context?.addLine(to: CGPoint(x: toPoint.x, y: toPoint.y))
        
        context?.setLineCap(.round)
        context?.setLineWidth(10.0)
        context?.setStrokeColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        context?.setBlendMode(.normal)
        context?.strokePath()
        
        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    @IBAction func predictBtnWasPressed(_ sender: Any) {
        guard let predectionImage = drawingImageView.image else { return }
        makePredection(image(with: predectionImage, scaleTo: CGSize(width: 28.0, height: 28.0)))
    }
    
    func makePredection(_ image: UIImage){
        
        guard let model = try? VNCoreMLModel(for: handwriting().model) else { return }
        let request = VNCoreMLRequest(model: model,completionHandler : resultMethod)
        guard let ciImage = CIImage(image: image) else { return  }
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
        try handler.perform([request])
        }catch{
            debugPrint(error)
        }
    }
    
    func resultMethod(request : VNRequest , error: Error?)
    {
        guard let results = request.results ,
        let resultsArray = results[0] as? VNCoreMLFeatureValueObservation ,
        let multiArrayValue = resultsArray.featureValue.multiArrayValue else { return }
        
        var predection : NSNumber = 0
        var compare : NSNumber = 0
        var atIndex : Int = 0
        var i: Int = 0
        
        while i  < multiArrayValue.count {
            compare = multiArrayValue[i]
            if compare.floatValue > predection.floatValue{
                predection = compare
                atIndex = i
            }
            
            i = i + 1
        }
        
        predictionLbl.text = "Digit may be : \(atIndex)"
    }
    
    func image(with image : UIImage, scaleTo newSize: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        drawingImageView.image = newImage
        return newImage ?? UIImage()
    }
    
    
}

