import Foundation
import ARKit

@available(iOS 11.3, *)
func parseReferenceImagesSet(_ images: Array<Dictionary<String, Any>>) -> Set<ARReferenceImage> {
    var results = Set<ARReferenceImage>(minimumCapacity: images.count)
    for image in images {
        if let parsed = parseReferenceImage(image) {
            results.insert(parsed)
        }
    }
    return results
}

@available(iOS 11.3, *)
func parseReferenceImage(_ dict: Dictionary<String, Any>) -> ARReferenceImage? {
    if let physicalWidth = dict["physicalWidth"] as? Double,
        let name = dict["name"] as? String,
        let image = getImageByName(name),
        let cgImage = image.cgImage {
        
        let referenceImage = ARReferenceImage(cgImage, orientation: CGImagePropertyOrientation.up, physicalWidth: CGFloat(physicalWidth))
        return referenceImage
    }
    return nil
}

func getImageByName(_ name: String) -> UIImage? {
    if let img = UIImage(named: name) {
        return img
    }
    if let path = Bundle.main.path(forResource: SwiftArkitPlugin.registrar!.lookupKey(forAsset: name), ofType: nil) {
        return UIImage(named: path)
    }
    do {
        let data = try Data.init(contentsOf: URL.init(string: name)!)
        return UIImage(data: data)
    } catch {
        
    }
    return nil
}
