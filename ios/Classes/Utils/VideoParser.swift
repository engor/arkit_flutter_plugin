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
    let size = CGSize(width: width, height: height)
    let videoNode = SKVideoNode(avPlayer: avPlayer)
    videoNode.size = size
    videoNode.anchorPoint = CGPoint(x: 0, y: 0)
    videoNode.name = name

    let skScene = SKScene(size: size)
    skScene.addChild(videoNode)
    skScene.scaleMode = .aspectFit
    
    let holder = VideoHolder(player: avPlayer)
    holder.repeatCount = params["repeat"] as! Int
    holder.volume = Float(params["volume"] as! Double)
    
    VideoHolder.store(name: name, holder: holder, play: true)

    return skScene
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
        holder.player.currentItem?.seek(to: CMTime.zero, completionHandler: nil)
        holder.player.play()
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
        items.removeValue(forKey: name)
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
        pauseAll()
        items.removeAll()
    }
}
