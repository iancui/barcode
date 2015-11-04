//
//  ViewController.swift
//  qrcode
//
//  Created by xiaobo on 15/4/7.
//  Copyright (c) 2015年 xiaobo. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

class ViewController: UIViewController ,AVCaptureMetadataOutputObjectsDelegate{

    var session:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var autoLockView:UIView?
    
    @IBOutlet weak var buttonReScan: UIButton!
    @IBOutlet weak var labelQR: UILabel!
    //重新扫描
    @IBAction func reScan(sender: AnyObject) {
        autoLockView?.hidden = true
        buttonReScan.hidden = true
        session?.startRunning()
    }
    // 停止扫描
    func stopScan(){
        buttonReScan.hidden = false
        self.view.bringSubviewToFront(buttonReScan)
        
        session?.stopRunning()
    }

    func launchApp(decodeStr:String){
        
        let alert = UIAlertController(title: "二维码", message: "是否打开\(decodeStr)", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "打开", style: .Destructive) { (_) -> Void in
            if let url = NSURL(string: decodeStr){
                if UIApplication.sharedApplication().canOpenURL(url) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style:.Cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = self.labelQR.frame
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 按钮隐藏
        buttonReScan.hidden = true
        session = AVCaptureSession()
        
        let divice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: divice)
            session!.addInput(input)
        } catch {
            print("摄像头不能打开")
            return
        }
        
        let output = AVCaptureMetadataOutput()
        session!.addOutput(output)
        
        //
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeFace]
        
        //
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill

        videoPreviewLayer?.frame = self.view.layer.bounds
        
        self.view.layer.addSublayer(videoPreviewLayer!)
        
        session?.startRunning()
        
        
        //把标签放到最上层
        view.bringSubviewToFront(labelQR)
        
        
        //自动锁定框
        autoLockView = UIView()
        autoLockView?.layer.borderColor = UIColor.greenColor().CGColor
        autoLockView?.layer.borderWidth = 2
        self.view.addSubview(autoLockView!)
        
        view.bringSubviewToFront(autoLockView!)
        
        
    }

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if metadataObjects == nil || metadataObjects.count == 0{
            autoLockView?.frame = CGRectZero
            labelQR.text = "正在扫描中..."
            return
        }
        if let obj = metadataObjects.first as? AVMetadataFaceObject {
            if obj.type == AVMetadataObjectTypeFace {
                let faceObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(obj) as! AVMetadataFaceObject
                
                autoLockView?.frame = faceObject.bounds
                autoLockView?.hidden = false
                view.bringSubviewToFront(autoLockView!)
                labelQR.text = "发现人脸！！"
                
            }
        }
        
        if let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
//            
            let codeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(obj) as! AVMetadataMachineReadableCodeObject

            switch obj.type {
            case AVMetadataObjectTypeEAN13Code:
                if let decodeStr = obj.stringValue {
                    
                    stopScan()
                    autoLockView?.frame = CGRectMake(codeObject.bounds.origin.x, codeObject.bounds.origin.y + codeObject.bounds.height/2 - 2, codeObject.bounds.width, 4)
                    autoLockView?.hidden = false
                    view.bringSubviewToFront(autoLockView!)
                    labelQR.text = "条形码:" + decodeStr
                    getGoodsName(decodeStr)
                    
                    
                }
            case AVMetadataObjectTypeQRCode:
                autoLockView?.frame = codeObject.bounds
                if let decodeStr = obj.stringValue {
                    stopScan()
                    labelQR.text = "二维码:" + decodeStr
                    autoLockView?.hidden = false
                    view.bringSubviewToFront(autoLockView!)
                    launchApp(decodeStr)
                }
            default: return
            }
        }
        
        
    }
    func getGoodsName(decodeStr:String){
        
        let baseUrl = "http://api.juheapi.com/jhbar/bar"

        
        Alamofire.request(.GET, baseUrl, parameters: ["appKey":"95244381357f5561d07144a55bdf1d24","pkg":"com.cuiswift.com","barcode":"6923450605332","cityid":"1"]).responseJSON { (response) -> Void in
            print(response.request)
        }
        
//        Alamofire.re
        
        
    }
    


}

