import Foundation
import AVFoundation
import SpriteKit
import SceneKit


func getVideoByParams(_ params: Dictionary<String, Any>) -> SKScene? {
    let url = URL(fileURLWithPath: params["url"] as! String)
    let avPlayerItem = AVPlayerItem(asset: AVAsset(url: url))
    
    let name = params["name"] as! String
    let avPlayer = AVPlayer(playerItem: avPlayerItem)
    
    let width = params["width"] as! Double
    let height = params["height"] as! Double
    let autoplay = params["autoplay"] as! Bool
    let chromaKeyColor = params["chromaKeyColor"] as? String
    
    let size = CGSize(width: width, height: height)
    let videoNode = SKVideoNode(avPlayer: avPlayer)
    videoNode.size = size
    videoNode.anchorPoint = CGPoint(x: 0, y: 0)
    videoNode.name = name

    let skScene = SKScene(size: size)
    skScene.scaleMode = .aspectFit

    if chromaKeyColor == nil {
        skScene.addChild(videoNode)
    } else {
        skScene.backgroundColor = UIColor.clear
        let effectNode = SKEffectNode()
        effectNode.filter = colorCubeFilterForChromaKey(color: chromaKeyColor!)
        effectNode.addChild(videoNode)
        skScene.addChild(effectNode)
    }
    
    let holder = VideoHolder(player: avPlayer)
    holder.repeatCount = params["repeat"] as! Int
    holder.volume = Float(params["volume"] as! Double)
    
    VideoHolder.store(name: name, holder: holder, play: autoplay)

    return skScene
}


func RGBtoHSV(r : Float, g : Float, b : Float) -> (h : Float, s : Float, v : Float) {
    var h : CGFloat = 0
    var s : CGFloat = 0
    var v : CGFloat = 0
    let col = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
    col.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
    return (Float(h), Float(s), Float(v))
}

func colorCubeFilterForChromaKey(color: String) -> CIFilter {

    let hue = RGBtoHSV(
        r: Float(Int(color.substring(with: 0..<2), radix: 16)!)/255,
        g: Float(Int(color.substring(with: 2..<4), radix: 16)!)/255,
        b: Float(Int(color.substring(with: 4..<6), radix: 16)!)/255
    )
    
    let hueRange: Float = 60.0 / 360 // degrees size pie shape that we want to replace
    let minHueAngle: Float = 0.3 - hueRange/2.0
    let maxHueAngle: Float = 0.3 + hueRange/2.0

    let size = 64
    var cubeData = [Float](repeating: 0, count: size * size * size * 4)
    var rgb: [Float] = [0, 0, 0]
    var hsv: (h : Float, s : Float, v : Float)
    var offset = 0

    for z in 0 ..< size {
        rgb[2] = Float(z) / Float(size) // blue value
        for y in 0 ..< size {
            rgb[1] = Float(y) / Float(size) // green value
            for x in 0 ..< size {

                rgb[0] = Float(x) / Float(size) // red value
                hsv = RGBtoHSV(r: rgb[0], g: rgb[1], b: rgb[2])
                // the condition checking hsv.s may need to be removed for your use-case
                let alpha: Float = (hsv.h > minHueAngle && hsv.h < maxHueAngle && hsv.s > 0.5) ? 0 : 1.0

                cubeData[offset] = rgb[0] * alpha
                cubeData[offset + 1] = rgb[1] * alpha
                cubeData[offset + 2] = rgb[2] * alpha
                cubeData[offset + 3] = alpha
                offset += 4
            }
        }
    }
    let b = cubeData.withUnsafeBufferPointer { Data(buffer: $0) }
    let data = b as NSData

    let colorCube = CIFilter(name: "CIColorCube", parameters: [
        "inputCubeDimension": size,
        "inputCubeData": data
    ])
    return colorCube!
}


class VideoHolder {
    static var items:Dictionary<String, VideoHolder> = [:]
    
    var player:AVPlayer
    var repeatCount:Int = 1
    var repeatTimes = 0
    var volume:Float = 1.0
    
    init (player:AVPlayer) {
        self.player = player
    }
    
    static func store(name:String, holder:VideoHolder, play:Bool = true) {
        items[name] = holder
        holder.repeatTimes = 0
        holder.player.volume = holder.volume

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(VideoHolder.playerItemDidReachEnd(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: holder.player.currentItem
        )

        if play {
            playVideo(holder)
        }
    }

    @objc static func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            VideoHolder.onPlayEnded(playerItem)
        }
    }
    
    static func onPlayEnded(_ item:AVPlayerItem) {
        for holder in items.values {
            if holder.player.currentItem == item {
                holder.repeatTimes += 1
                if holder.repeatCount == -1 || holder.repeatTimes < holder.repeatCount {
                    VideoHolder.playVideo(holder)
                }
                break
            }
        }
    }
    
    private static func playVideo(_ holder:VideoHolder) {
        DispatchQueue.main.async {
            holder.player.currentItem?.seek(to: CMTime.zero, completionHandler: nil)
            holder.player.play()
        }
    }
    
    static func pauseVideo(_ name:String) {
        if let holder = items[name] {
            holder.player.pause()
        }
    }
    
    static func resumeVideo(_ name:String) {
        if let holder = items[name] {
            holder.player.play()
        }
    }
    
    static func disposeVideo(node:SCNNode) {
        if let videoScene = node.geometry?.firstMaterial?.diffuse.contents as? SKScene {
            if let nodeName = videoScene.children[0].name {
                disposeVideo(name: nodeName)
            }
        }
        for child in node.childNodes {
          disposeVideo(node: child)
        }
    }
    
    static func disposeVideo(name:String) {
        pauseVideo(name)
        
        let holder = items.removeValue(forKey: name)
        holder?.player.replaceCurrentItem(with: nil)
    }
    
    static func pauseAll() {
        for holder in items.values {
            holder.player.pause()
        }
    }
    
    static func resumeAll() {
        for holder in items.values {
            holder.player.play()
        }
    }
    
    static func disposeAll() {
        for name in items.keys {
            disposeVideo(name: name)
        }
    }
}
