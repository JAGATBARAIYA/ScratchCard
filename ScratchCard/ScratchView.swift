//
//  ScratchView.swift
//  ScratchCard
//
//  Created by JoeJoe on 2016/4/15.
//  Copyright © 2016年 JoeJoe. All rights reserved.
//

import Foundation
import UIKit

var width: Int!
var height: Int!
var location: CGPoint!
var previousLocation: CGPoint!
var firstTouch: Bool!
var scratchable: CGImage!
var scratched: CGImage!
var alphaPixels: CGContext!
var provider: CGDataProvider!
var maskImage: String!
var scratchWidth: CGFloat!
var contentLayer: CALayer!

internal protocol ScratchViewDelegate: class {
    func began(_ view: ScratchView)
    func moved(_ view: ScratchView)
    func ended(_ view: ScratchView)
}

open class ScratchView: UIView {
    
    internal weak var delegate: ScratchViewDelegate!
    internal var position: CGPoint!
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.Init()
    }
    
    init(frame: CGRect, MaskImage: String, ScratchWidth: CGFloat) {
        super.init(frame: frame)
        maskImage = MaskImage
        scratchWidth = ScratchWidth
        self.Init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.InitXib()
    }
    
    fileprivate func Init() {
        scratchable = UIImage(named: maskImage)!.cgImage
        width = (Int)(self.frame.width)
        height = (Int)(self.frame.height)
        
        self.isOpaque = false
        let colorspace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let pixels: CFMutableData = CFDataCreateMutable(nil, width * height * 4)
        
        alphaPixels = CGContext( data: CFDataGetMutableBytePtr(pixels), width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorspace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        provider = CGDataProvider(data: pixels)
        
        alphaPixels.setFillColor(red: 0, green: 0, blue: 0, alpha: 0)
        alphaPixels.setStrokeColor(red: 255, green: 255, blue: 255, alpha: 1)
        alphaPixels.setLineWidth(scratchWidth)
        alphaPixels.setLineCap(CGLineCap.round)
        
        let mask: CGImage = CGImage(maskWidth: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, provider: provider, decode: nil, shouldInterpolate: false)!
        var maskLayer = CAShapeLayer()
        maskLayer.frame =  CGRect(x:0, y:0, width:width, height:height)
        maskLayer.contents = mask
        
        contentLayer = CALayer()
        contentLayer.frame =  CGRect(x:0, y:0, width:width, height:height)
        contentLayer.contents = scratchable
        contentLayer.mask = maskLayer
        
    }
    
    fileprivate func InitXib() {
        
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                firstTouch = true
                location = CGPoint(x: touch.location(in: self).x, y: self.frame.size.height-touch.location(in: self).y)
                
                position = location
                
                if self.delegate != nil {
                    self.delegate.began(self)
                }
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                if firstTouch! {
                    firstTouch = false
                    previousLocation =  CGPoint(x: touch.previousLocation(in: self).x, y: self.frame.size.height-touch.previousLocation(in: self).y)
                } else {
                    
                    location = CGPoint(x: touch.location(in: self).x, y: self.frame.size.height-touch.location(in: self).y)
                    previousLocation = CGPoint(x: touch.previousLocation(in: self).x, y: self.frame.size.height-touch.previousLocation(in: self).y)
                }
                
                position = previousLocation
                
                renderLineFromPoint(previousLocation, end: location)
                
                if self.delegate != nil {
                    self.delegate.moved(self)
                }
            }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>,
        with event: UIEvent?) {
            if let touch = touches.first {
                if firstTouch! {
                    firstTouch = false
                    previousLocation =  CGPoint(x: touch.previousLocation(in: self).x, y: self.frame.size.height-touch.previousLocation(in: self).y)
                    
                    position = previousLocation
                    
                    renderLineFromPoint(previousLocation, end: location)
                    
                    if self.delegate != nil {
                        self.delegate.ended(self)
                    }
                }
            }
    }
    
    override open func draw(_ rect: CGRect) {
        UIGraphicsGetCurrentContext()?.saveGState()
        contentLayer.render(in:  UIGraphicsGetCurrentContext()!)
        UIGraphicsGetCurrentContext()?.restoreGState()
    }
    
    func renderLineFromPoint(_ start: CGPoint, end: CGPoint) {
        alphaPixels.move(to: CGPoint(x: start.x, y: start.y))
        alphaPixels.addLine(to: CGPoint(x: end.x, y: end.y))
        alphaPixels.strokePath()
        
        self.setNeedsDisplay()
    }
    
    internal func getAlphaPixelPercent() -> Double {
        let pixelData = provider.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let imageWidth: size_t = alphaPixels.makeImage()!.width
        let imageHeight: size_t = alphaPixels.makeImage()!.height
        
        var byteIndex: Int  = 0
        var count: Double = 0
        
        for _ in 0...imageWidth * imageHeight {
            if data[byteIndex] != 0 {
                count += 1
            }
            byteIndex += 4
        }
        
        return count / Double(imageWidth * imageHeight)
    }
}
