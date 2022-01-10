import ARKit

var animHandlers: Dictionary<String, AnimationHandler> = [:]

extension FlutterArkitView {
    
    func onAnimate(_ arguments: Dictionary<String, Any>) {
        guard let nodeName = arguments["nodeName"] as? String
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
//        if let node = sceneView.scene.rootNode.childNode(withName: nodeName, recursively: true) {
            print("to animate: \(nodeName)")
            var handler = animHandlers[nodeName]
            if handler == nil {
                let node = sceneView.scene.rootNode.childNode(withName: nodeName, recursively: true)
                handler = AnimationHandler(view: sceneView, node: node!)
                handler?.addAllPlayers(node!)
                animHandlers[nodeName] = handler
                handler?.animStateListener = {(percent:Double) in
                    self.channel.invokeMethod("onAnimChanged", arguments: [
                        "nodeName": nodeName,
                        "state": "ended",
                        "percent": percent
                    ])
                }
            }
            if let handler = handler {
                if let progress = arguments["progress"] as? Double {
                    print("set progress")
                    handler.setProgress(percent: progress)
                }
                if let pair = arguments["toggle"] as? Array<Double> {
                    print("set toggle")
                    handler.toggleInterval(pair: pair)
                }
                
            }
//        } else {
//            logPluginError("node not found", toChannel: channel)
//        }
    }
    
    func onAddNode(_ arguments: Dictionary<String, Any>) {
        let geometryArguments = arguments["geometry"] as? Dictionary<String, Any>
        let geometry = createGeometry(geometryArguments, withDevice: sceneView.device)
        let node = createNode(geometry, fromDict: arguments, forDevice: sceneView.device)
        if let parentNodeName = arguments["parentNodeName"] as? String {
            let parentNode = sceneView.scene.rootNode.childNode(withName: parentNodeName, recursively: true)
            parentNode?.addChildNode(node)
        } else {
            sceneView.scene.rootNode.addChildNode(node)
        }
        sceneView.sceneTime=1
    }
    
    func onRemoveNode(_ arguments: Dictionary<String, Any>) {
        guard let nodeName = arguments["nodeName"] as? String else {
            logPluginError("nodeName deserialization failed", toChannel: channel)
            return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: nodeName, recursively: true) {
            node.removeFromParentNode()
            VideoHolder.disposeVideo(node: node)
        }
    }
  
    func onRemoveAnchor(_ arguments: Dictionary<String, Any>) {
        guard let anchorIdentifier = arguments["anchorIdentifier"] as? String else {
            logPluginError("anchorIdentifier deserialization failed", toChannel: channel)
            return
        }
        if let anchor = sceneView.session.currentFrame?.anchors.first(where:{ $0.identifier.uuidString == anchorIdentifier }) {
            sceneView.session.remove(anchor: anchor)
        }
    }
    
    func onGetNodeBoundingBox(_ arguments: Dictionary<String, Any>, _ result:FlutterResult) {
        guard let geometryArguments = arguments["geometry"] as? Dictionary<String, Any> else {
            logPluginError("geometryArguments deserialization failed", toChannel: channel)
            result(nil)
            return
        }
        let geometry = createGeometry(geometryArguments, withDevice: sceneView.device)
        let node = createNode(geometry, fromDict: arguments, forDevice: sceneView.device)
        
        let resArray = [serializeVector(node.boundingBox.min), serializeVector(node.boundingBox.max)]
        result(resArray)
    }
    
    func onTransformChanged(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let params = arguments["transformation"] as? Array<NSNumber>
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            node.transform = deserializeMatrix4(params)
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onIsHiddenChanged(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let params = arguments["isHidden"] as? Bool
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            node.isHidden = params
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onUpdateSingleProperty(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let args = arguments["property"] as? Dictionary<String, Any>,
            let propertyName = args["propertyName"] as? String,
            let propertyValue = args["propertyValue"],
            let keyProperty = args["keyProperty"] as? String
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            if let obj = node.value(forKey: keyProperty) as? NSObject {
                obj.setValue(propertyValue, forKey: propertyName)
            } else {
                logPluginError("value is not a NSObject", toChannel: channel)
            }
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onUpdateMaterials(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let rawMaterials = arguments["materials"] as? Array<Dictionary<String, Any>>
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            
            let materials = parseMaterials(rawMaterials)
            node.geometry?.materials = materials
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onUpdateFaceGeometry(_ arguments: Dictionary<String, Any>) {
        #if !DISABLE_TRUEDEPTH_API
        guard let name = arguments["name"] as? String,
            let param = arguments["geometry"] as? Dictionary<String, Any>,
            let fromAnchorId = param["fromAnchorId"] as? String
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true),
            let geometry = node.geometry as? ARSCNFaceGeometry,
            let anchor = sceneView.session.currentFrame?.anchors.first(where: {$0.identifier.uuidString == fromAnchorId}) as? ARFaceAnchor
        {
            
            geometry.update(from: anchor.geometry)
        } else {
            logPluginError("node not found, geometry was empty, or anchor not found", toChannel: channel)
        }
        #else
        logPluginError("TRUEDEPTH_API disabled", toChannel: channel)
        #endif
    }
    
    func onPerformHitTest(_ arguments: Dictionary<String, Any>, _ result:FlutterResult) {
        guard let x = arguments["x"] as? Double,
            let y = arguments["y"] as? Double else {
                logPluginError("deserialization failed", toChannel: channel)
                result(nil)
                return
        }
        let viewWidth = sceneView.bounds.size.width
        let viewHeight = sceneView.bounds.size.height
        let location = CGPoint(x: viewWidth * CGFloat(x), y: viewHeight * CGFloat(y));
        let arHitResults = getARHitResultsArray(sceneView, atLocation: location)
        result(arHitResults)
    }
    
    func onGetLightEstimate(_ result:FlutterResult) {
        let frame = sceneView.session.currentFrame
        if let lightEstimate = frame?.lightEstimate {
            let res = ["ambientIntensity": lightEstimate.ambientIntensity, "ambientColorTemperature": lightEstimate.ambientColorTemperature]
            result(res)
        } else {
            result(nil)
        }
    }
    
    func onProjectPoint(_ arguments: Dictionary<String, Any>, _ result:FlutterResult) {
        guard let rawPoint = arguments["point"] as? Array<Double> else {
            logPluginError("deserialization failed", toChannel: channel)
            result(nil)
            return
        }
        let point = deserizlieVector3(rawPoint)
        let projectedPoint = sceneView.projectPoint(point)
        let res = serializeVector(projectedPoint)
        result(res)
    }
    
    func onCameraProjectionMatrix(_ result:FlutterResult) {
        if let frame = sceneView.session.currentFrame {
            let matrix = serializeMatrix(frame.camera.projectionMatrix)
            result(matrix)
        } else {
            result(nil)
        }
    }
  
    func onPointOfViewTransform(_ result:FlutterResult) {
        if let pointOfView = sceneView.pointOfView {
          let matrix = serializeMatrix(pointOfView.simdWorldTransform)
            result(matrix)
        } else {
            result(nil)
        }
    }
    
    func onPlayAnimation(_ arguments: Dictionary<String, Any>) {
        guard let key = arguments["key"] as? String,
            let sceneName = arguments["sceneName"] as? String,
            let animationIdentifier = arguments["animationIdentifier"] as? String else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        
        if let sceneUrl = Bundle.main.url(forResource: sceneName, withExtension: "dae"),
            let sceneSource = SCNSceneSource(url: sceneUrl, options: nil),
            let animation = sceneSource.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            animation.repeatCount = 1
            animation.fadeInDuration = 1
            animation.fadeOutDuration = 0.5
            sceneView.scene.rootNode.addAnimation(animation, forKey: key)
        } else {
            logPluginError("animation failed", toChannel: channel)
        }
    }
    
    func onStopAnimation(_ arguments: Dictionary<String, Any>) {
        guard let key = arguments["key"] as? String else {
            logPluginError("deserialization failed", toChannel: channel)
            return
        }
        sceneView.scene.rootNode.removeAnimation(forKey: key)
    }

    func onCameraEulerAngles(_ result:FlutterResult){
        if let frame = sceneView.session.currentFrame {
            let res = serializeArray(frame.camera.eulerAngles)
            result(res)
        } else {
            result(nil)
        }
   }

   func onGetSnapshot(_ result:FlutterResult) {
        let snapshotImage = sceneView.snapshot()
        if let bytes = snapshotImage.pngData() {
            let data = FlutterStandardTypedData(bytes:bytes)
            result(data)
        } else {
            result(nil)
        }
    }
    
    func onDispose(_ result:FlutterResult) {
        sceneView.session.pause()
        self.channel.setMethodCallHandler(nil)
        result(nil)
    }
    
    func onPause(_ result:FlutterResult) {
        sceneView.session.pause()
        VideoHolder.pauseAll()
        result(nil)
    }
    
    func onResume(_ result:FlutterResult) {
        sceneView.session.run(sceneView.session.configuration!)
        VideoHolder.resumeAll()
        result(nil)
    }
}
