
import ARKit


class AnimationHandler {
    
    var sceneView:ARSCNView
    var animations:[AnimationInstance] = []
    var anim = false
    var animStateListener:((_ percent:Double) -> Void)? = nil
    
    init(view:ARSCNView, node:SCNNode) {
        self.sceneView = view
        view.isPlaying = false
        view.rendersContinuously = true
    }
    
    func addAnim(_ player:SCNAnimationPlayer) {
        let animation = AnimationInstance(player: player)
        animations.append(animation)
    }
    
    func addAllPlayers(_ node:SCNNode) {
        var players:[SCNAnimationPlayer] = []
        extractAnimPlayers(node, &players)
        for p in players {
            addAnim(p)
        }
    }
    
    func extractAnimPlayers(_ node:SCNNode, _ players: inout [SCNAnimationPlayer]) {
        let keys = node.animationKeys
        if !keys.isEmpty {
            let key = keys.first
            if let player = node.animationPlayer(forKey: key!) {
                players.append(player)
            }
        }
        for n in node.childNodes {
            extractAnimPlayers(n, &players)
        }
    }
    
    func setProgress(percent:TimeInterval) {
        for anim in animations {
            let progress = anim.setAnimationProgress(progressPercent: percent)
            sceneView.sceneTime = progress
        }
    }
    
    func update(_ deltaSeconds:TimeInterval) {
        if (!anim) {
            return
        }
        let wasAnim = animations[0].anim
        var progress = 0.0
        for anim in animations {
            progress = anim.update(deltaSeconds: deltaSeconds)
        }
        sceneView.sceneTime = progress
        let nowAnim = animations[0].anim
        if wasAnim && !nowAnim {
            onAnimEnded(percent: progress * 100.0 / animations[0].duration)
        }
    }
    
    func onAnimEnded(percent:Double) {
        animStateListener?(percent)
    }
    
    func pause() {
        anim = false
        for anim in animations {
            anim.pause()
        }
    }

    func resume() {
        anim = true
        for anim in animations {
            anim.resume()
        }
    }
    
    func toggleInterval(pair: Array<Double>) {
        for anim in animations {
            anim.toggleInterval(pair: pair)
        }
        resume()
    }
}


class AnimationInstance {
    var animator: SCNAnimationPlayer
    var progress = 0.0
    var duration = 0.0
    var target = 0.0
    var dir = 0.0
    var anim = false
    var toggleIndex = 0
    var stored: Array<Double> = []
    var next: Array<Double>? = nil

    init(player:SCNAnimationPlayer) {
        animator = player
        duration = player.animation.duration
        player.animation.usesSceneTimeBase = true
    }
    
    func pause() {
        anim = false
        animator.paused = true
    }

    func resume() {
        anim = true
        animator.paused = false
    }
    
    func update(deltaSeconds: Double) -> Double {
        progress += deltaSeconds * dir
        if (dir > 0 && progress >= target) {
            progress = target
            onAnimEnded()
        } else if (dir < 0 && progress <= target) {
            progress = target
            onAnimEnded()
        }
        return refreshProgress()
    }

    func refreshProgress() -> Double {
        return progress
    }

    func onAnimEnded() {
        pause()
        if (next != nil) {
            toggleInterval(pair: next!)
            next = nil
        }
    }

    func toggleInterval(pair: Array<Double>) {

        if (anim) {
            return
        }
        
        var mod = (toggleIndex % 2)

        let theSame = checkTheSame(pair: pair)
        if (!theSame) {
            // another interval
            if (mod == 1) {
                // play backward prev anim
                toggleInterval(pair: stored)
                next = pair
                return
            }
            toggleIndex = 0
            mod = 0
        }

        stored = pair

        var i1 = 0
        var i2 = 1
        if (mod == 1) {
            i1 = 1
            i2 = 0
        }
        let from = pair[i1] * duration
        let to = pair[i2] * duration

        toggleIndex += 1

        dir = (from < to) ? 1.0 : -1.0

        progress = from
        target = to

        resume()
    }

    func checkTheSame(pair: Array<Double>) -> Bool {
        if (stored.count != pair.count) {
            return false
        }
        for i in 0...pair.count-1 {
            if (pair[i] != stored[i]) {
                return false
            }
        }
        return true
    }

    func setAnimationProgress(progressPercent: Double) -> Double {
        progress = progressPercent * duration
        target = progress
        dir = 1.0
        return refreshProgress()
    }
}
