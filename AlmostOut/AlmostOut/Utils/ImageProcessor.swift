//
//  ImageProcessor.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import UIKit

class ImageProcessor {
    static func compressImage(_ image: UIImage, maxSizeKB: Int = 200) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
    
    static func generateThumbnail(from image: UIImage, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumbnail
    }
    
    static func resizeImage(_ image: UIImage, maxWidth: CGFloat = 800) -> UIImage? {
        let ratio = image.size.width / image.size.height
        let newWidth = min(image.size.width, maxWidth)
        let newHeight = newWidth / ratio
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}
