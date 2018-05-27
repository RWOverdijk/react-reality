import Foundation
import SceneKit
import ARKit
@objc(RHDSceneManager)
class RHDSceneManager:RCTEventEmitter, ARSessionDelegate {
    static var sharedInstance:RHDSceneManager?
    override init() {
        super.init()
        if let s = RHDSceneManager.sharedInstance {
            s.listenedEvents = [:]
        }
        RHDSceneManager.sharedInstance = self
    }
    var secondaryView:SCNView?
    var scene:SCNScene?
    var session:ARSession?
    var configuration:ARWorldTrackingConfiguration = ARWorldTrackingConfiguration()
    //MARK:Node Management
    var nodes:[String:SCNNode] = [:]
    var orphans:[String:[SCNNode]] = [:]
    var pv:ARSCNView?
    func addNode(node: SCNNode, parent: String) {
        //Must have names or else we ditch
        guard
            let name = node.name
        
        else { return }
        nodes[name] = node
        NSLog("Added node with name: " + name)
        if parent == "" {
            if let s = scene {
                s.rootNode.addChildNode(node)
                fixOrphans()
            } else {
                if let _ = orphans[""] {
                    orphans[""]!.append(node)
                } else {
                    orphans[""] = [node]
                }
            }
        } else if let baseNode = baseNodes[parent] {
            baseNode.addChildNode(node)
        } else if let n = nodes[parent] {
            n.addChildNode(node)
            fixOrphans()
        } else {
            if let _ = orphans[parent] {
                orphans[parent]!.append(node)
            } else {
                orphans[parent] = [node]
            }
        }
    }
    var isFixingOrphans = false
    func fixOrphans() {
        guard !isFixingOrphans else { return }
        isFixingOrphans = true
        orphans.forEach() {parentid, ns in
            if parentid == "" {
                guard let _ = scene else { return }
                let nns = ns
                orphans.removeValue(forKey: parentid)
                nns.forEach() { node in
                    addNode(node: node, parent: parentid)
                }
            } else if let _  = baseNodes[parentid] {
                let nns = ns
                orphans.removeValue(forKey: parentid)
                nns.forEach() { node in
                    addNode(node: node, parent: parentid)
                }
            } else if let _ = nodes[parentid] {
                let nns = ns
                orphans.removeValue(forKey: parentid)
                nns.forEach() { node in
                    addNode(node: node, parent: parentid)
                }
            }
        }
        isFixingOrphans = false
    }
    func removeNode(id: String) {
        guard let n = nodes[id], baseNodes[id] == nil else { return }
        removeNode(node: n)
    }
    func removeNode(node: SCNNode) {
        node.removeFromParentNode()
        if let n  = node.name {
            nodes.removeValue(forKey: n)
        }
        node.childNodes.forEach() { cn in
            removeNode(node: cn)
        }
    }
    @objc func addNode(_ node:SCNNode, parentID: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        addNode(node: node, parent: parentID);
        resolve(true)
    }
    @objc func removeNode(_ id: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        removeNode(id: id)
        resolve(true)
    }
    @objc func updateNode(_ forNode: String, newProps: jsonType, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let n = nodes[forNode] else { reject("no_node", "updateNode: No Node with name " + forNode, nil); return }
        setNodeProperties(n, properties: newProps)
        resolve(true)
    }
    @objc func setBox(_ g: SCNBox, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setCapsule(_ g: SCNCapsule, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setCone(_ g: SCNCone, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setCylinder(_ g: SCNCylinder, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setPlane(_ g: SCNPlane, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setPyramid(_ g: SCNPyramid, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setSphere(_ g: SCNSphere, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setText(_ g: SCNText, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setTorus(_ g: SCNTorus, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setTube(_ g: SCNTube, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setGeometry(g, forNode: forNode, resolve: resolve, reject: reject);
    }
    @objc func setGeometry(_ geometry: SCNGeometry, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let n = nodes[forNode] else { reject("no_node", "setGeometry:No Node with name " + forNode, nil); return }
        n.geometry = geometry;
//        if let g = n.geometry {
//            if type(of: g) == type(of: geometry) {
//
//            } else {
//                n.geometry = geometry // New Mount
//            }
//        } else {
//            n.geometry = geometry;
//        }
        resolve(true)
    }
    @objc func setMaterial(_ material:SCNMaterial, forNode: String, atPosition: Int, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let n = nodes[forNode] else { reject("no_node", "setMaterial:No Node with name " + forNode, nil); return }
        guard let g = n.geometry else { reject("no_geometry", "No Geometry at node with name " + forNode, nil); return }
        if g.materials.count > atPosition {
            g.replaceMaterial(at: atPosition, with: material)
        } else if g.materials.count == atPosition {
            g.materials.append(material)
        } else {
            while g.materials.count < atPosition  {
                g.materials.append(SCNMaterial())
            }
            g.materials.append(material)
        }
    }
    @objc func setMaterialProperty(_ json: jsonType, propertyName: String, forMaterialAtPosition: Int, forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let n = nodes[forNode] else { reject("no_node", "setMaterialProperty:No Node with name " + forNode, nil); return }
        guard let g = n.geometry else { reject("no_geometry", "No Geometry at node with name " + forNode, nil); return }
        guard forMaterialAtPosition < g.materials.count else { reject("no_matieral", "No Material set at position " + String(forMaterialAtPosition) + "for node with name " + forNode, nil); return }
        let m = g.materials[forMaterialAtPosition]
        var mp:SCNMaterialProperty = SCNMaterialProperty()
        switch(propertyName) {
        case "diffuse":
             mp = m.diffuse
        case "specular":
             mp = m.specular
        case "normal":
             mp = m.normal
        default:
            reject("invalid_property", "Not a valid material property: " + propertyName, nil)
            return
        }
        setMaterialPropertyContents(json, materialProperty: mp)
        resolve(true) 
    }
    @objc func removeGeometry(_ forNode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let n = nodes[forNode] else { reject("no_node", "removeGeometry:No Node with name " + forNode, nil); return }
        n.geometry = nil
        resolve(true)
    }
    @objc func removeMaterial(_ forNode: String, atPosition: Int, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard atPosition > -1 else { reject("bad_position", "Position must be 0 or greater", nil); return}
        guard let n = nodes[forNode] else { reject("no_node", "removeMaterial:No Node with name " + forNode, nil); return }
        guard let g = n.geometry else { reject("no_geometry", "No Geometry at node with name " + forNode, nil); return }
        guard g.materials.count > atPosition else  { reject("bad_position", "Position is higher than allowed for this geometry", nil); return}
        g.removeMaterial(at: atPosition)
        resolve(true)
    }
    //MARK:SKNode Functions
    var SKNodes:[String:SKNode] = [:]
    var SKOrphans:[String:[SKNode]] = [:]
    var SKScenes:[String:Int] = [:]
    @objc func addSKSceneReference(_ scene: SKScene, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        addSKNode(scene, toParent: "")
        resolve(true)
    }
    @objc func addSKSceneByReference(_ sceneName: String, forNode: String, atPosition: Int, withType: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let scene = SKNodes[sceneName] as? SKScene else { reject("no_scene", "No Scene with Name: " + sceneName, nil); return}
        addSKScene(scene, forNode: forNode, atPosition: atPosition, withType: withType, resolve: resolve, reject: reject)
    }
    @objc func addSKScene(_ scene:SKScene, forNode: String, atPosition: Int, withType: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let n = nodes[forNode] else { reject("no_node", "addSKScene: No Node with name " + forNode, nil); return }
        guard let g = n.geometry else { reject("no_geometry", "No Geometry at node with name " + forNode, nil); return }
        let m = g.materials[atPosition]
        var mp:SCNMaterialProperty
        switch(withType) {
        case "diffuse":
            mp = m.diffuse
        case "normal":
            mp = m.normal
        case "specular":
            mp = m.specular
        default:
            reject("invalid_materialproperty", "Invalid Matieral Property Type: " + withType, nil)
            return
        }
        if let sksname = scene.name {
            if let count = SKScenes[sksname] {
                SKScenes[sksname] = count + 1
                if let s = SKNodes[sksname] {
                    mp.contents = s
                    addSKNode(s, toParent: "")
                } else {
                    mp.contents = scene
                    addSKNode(scene, toParent: "")
                }
            } else {
                SKScenes[sksname] = 1
                addSKNode(scene, toParent: "")
                mp.contents = scene
            }
        } else {
            addSKNode(scene, toParent: "")
            mp.contents = scene
        }
        resolve(true)
    }
    @objc func updateSKScene(_ scene:jsonType, forNode: String, atPosition: Int, withType: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let n = nodes[forNode] else { reject("no_node", "addSKScene: No Node with name " + forNode, nil); return }
        guard let g = n.geometry else { reject("no_geometry", "No Geometry at node with name " + forNode, nil); return }
        let m = g.materials[atPosition]
        var mp:SCNMaterialProperty
        switch(withType) {
        case "diffuse":
            mp = m.diffuse
        case "normal":
            mp = m.normal
        case "specular":
            mp = m.specular
        default:
            reject("invalid_materialproperty", "Invalid Matieral Property Type: " + withType, nil)
            return
        }
        if let thisScene = mp.contents as? SKScene {
            doUpdateSKScene(thisScene, json: scene)
            resolve(true)
        } else {
            reject("no_scene", "Did not find scene", nil)
        }
    }
        
    @objc func setSKLabelNode(_ node: SKLabelNode, toParent: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        setSKNode(node, toParent: toParent, resolve: resolve, reject: reject)
    }
    @objc func updateSKLabelNode(_ json: jsonType, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard  let s = json["name"] as? String, let n = SKNodes[s] as? SKLabelNode else { reject("no_node", "No node with this name", nil); return }
        doUpdateSKLabelNode(n, json: json)
        resolve(true)
        
    }
    @objc func setSKNode(_ node: SKNode, toParent: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        if let s = node.name, let o = SKNodes[s], let os = o.name {
            removeSKNode(os)
        }
        addSKNode(node, toParent: toParent);
        resolve(true)
    }
    func addSKNode(_ node: SKNode, toParent: String) {
        if let n = node.name {
            SKNodes[n] = node
            NSLog("Adding SKNode id " + n + " to parent " + toParent)
        }
        if toParent == "" {
            fixSKOrphans()
        } else if let p = SKNodes[toParent] {
            p.addChild(node)
            fixSKOrphans()
            
        } else {
            if let _ = SKOrphans[toParent] {
                SKOrphans[toParent]?.append(node)
            } else {
                SKOrphans[toParent] = [node]
            }
        }
    }
    @objc func removeSKNode(_ name: String, resolve:RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        removeSKNode(name)
        
    }
    func removeSKNode(_ name:String) {
        if let n = SKNodes[name] {
            if let _ = n.parent {
                n.removeFromParent()
            }
            SKNodes.removeValue(forKey: name)
            for c:SKNode in n.children {
                if let s = c.name {
                    removeSKNode(s)
                }
            }
        }
    }
    @objc func removeSKScene(_ forNode: String, atPosition: Int, withType: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let n = nodes[forNode] else { reject("no_node", "removeSKScene: No Node with name " + forNode, nil); return }
        guard let g = n.geometry else { reject("no_geometry", "No Geometry at node with name " + forNode, nil); return }
        let m = g.materials[atPosition]
        var mp:SCNMaterialProperty
        switch(withType) {
        case "diffuse":
            mp = m.diffuse
        case "normal":
            mp = m.normal
        case "specular":
            mp = m.specular
        default:
            reject("invalid_materialproperty", "Invalid Matieral Property Type: " + withType, nil)
            return
        }
        guard let sks = mp.contents as? SKScene else { reject("no_scene", "No scene present", nil); return }
        mp.contents = nil
        if let sksname = sks.name, let base = SKScenes[sksname] {
            SKScenes[sksname] = base - 1
            if SKScenes[sksname] == 0 {
                removeSKNode(sksname)
            }
        }
    }
    var isFixingSKOrphans = false
    func fixSKOrphans() {
        if isFixingSKOrphans { return }
        isFixingSKOrphans = true
        SKOrphans.forEach() { parentID, nodes in
            if let _ = SKNodes[parentID] {
                nodes.forEach() { node in
                    addSKNode(node, toParent: parentID)
                }
                SKOrphans[parentID] = nil
            }
        }
        isFixingSKOrphans = false
    }
    //MARK:Deprecated SKNode Functions
    @objc func addSKLabelNode(_ node: SKLabelNode, toParent: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        addSKNode(node, toParent: toParent, resolve: resolve, reject: reject)
    }
    
    @objc func addSKNode(_ node: SKNode, toParent: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        addSKNode(node, toParent: toParent)
        resolve(true)
    }
    //MARK:Session Management
    @objc func clear(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let s = scene else { reject("no_scene", "No scene is loaded", nil); return }
        s.rootNode.childNodes.forEach() { cn in
            cn.removeFromParentNode()
        }
        nodes = [:]
        resolve(true)
    }
    @objc func resume(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let _ = session else { reject("no_session", "No session loaded", nil); return }
        doResume()
        resolve(true)
    }
    func doResume() {
        guard let s = session else { return }
        s.run(configuration)
        fixOrphans()
    }
    @objc func pause(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let s = session else { reject("no_session", "No session is loaded", nil); return }
        s.pause()
        resolve(true)
    }//MARK: Animation Methods
    var animationDuration:CFTimeInterval = 0
    @objc func setAnimation(_ seconds: Double, type: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        animationDuration = seconds
        animationType = type
        updateAnimation()
        resolve(true)
    }
    @objc func setAnimationDuration(_ seconds: Double, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        animationDuration = seconds
        updateAnimation()
        resolve(true)
    }
    var animationType = "both"
    @objc func setAnimationType(_ type: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        animationType = type
        resolve(true)
    }
    func updateAnimation() {
        SCNTransaction.animationDuration = animationDuration
        var timingFunc:String = kCAMediaTimingFunctionEaseInEaseOut
        switch(animationType) {
        case "none": timingFunc = kCAMediaTimingFunctionLinear
        case "out": timingFunc = kCAMediaTimingFunctionEaseOut
        case "in": timingFunc = kCAMediaTimingFunctionEaseIn
        case "both": timingFunc = kCAMediaTimingFunctionEaseInEaseOut
        default: timingFunc = kCAMediaTimingFunctionEaseInEaseOut
        }
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: timingFunc)

    }
    //MARK:RCTBridgeModule methods
    override func constantsToExport() -> [AnyHashable : Any]! {
        //Exporting type/enum constants
        let out:[AnyHashable:Any] =  [
            "ARHitTestResultType": [
                "FeaturePoint": ARHitTestResult.ResultType.featurePoint,
                "EstimatedHorizontalPlane": ARHitTestResult.ResultType.estimatedHorizontalPlane,
                "ExistingPlane": ARHitTestResult.ResultType.existingPlane,
                "ExistingPlaneUsingExtent": ARHitTestResult.ResultType.existingPlaneUsingExtent
            ],
            "LightingModel": [
                "Constant": SCNMaterial.LightingModel.constant,
                "Blinn": SCNMaterial.LightingModel.blinn,
                "Lambert": SCNMaterial.LightingModel.lambert,
                "Phong": SCNMaterial.LightingModel.phong,
                "PhysicallyBased": SCNMaterial.LightingModel.physicallyBased
            ],
            "LightType":[
                "Ambient": SCNLight.LightType.ambient,
                "Directional": SCNLight.LightType.directional,
                "Omni": SCNLight.LightType.omni,
                "Probe": SCNLight.LightType.probe,
                "Spot": SCNLight.LightType.spot,
                "IES": SCNLight.LightType.IES
            ],
            "ShadowMode":[
                "Forward": SCNShadowMode.forward,
                "Deferred": SCNShadowMode.deferred,
                "ModeModulated": SCNShadowMode.modulated
            ],
            "ColorMask":[
                "All": SCNColorMask.all,
                "None": 0,
                "Alpha": SCNColorMask.alpha,
                "Blue": SCNColorMask.blue,
                "Red": SCNColorMask.red,
                "Green": SCNColorMask.green
            ],
            "ShaderModifierEntryPoint":[
                "Geometry": SCNShaderModifierEntryPoint.geometry,
                "Surface": SCNShaderModifierEntryPoint.surface,
                "LightingModel": SCNShaderModifierEntryPoint.lightingModel,
                "Fragment": SCNShaderModifierEntryPoint.fragment
            ],
            "BlendMode":[
                "Alpha": SCNBlendMode.alpha,
                "Add": SCNBlendMode.add,
                "Subtract": SCNBlendMode.subtract,
                "Multiply": SCNBlendMode.multiply,
                "Screen": SCNBlendMode.screen,
                "Replace": SCNBlendMode.replace
            ],
            "ChamferMode":[
                "Both": SCNChamferMode.both,
                "Back": SCNChamferMode.back,
                "Front": SCNChamferMode.front
            ],
            "ARWorldAlignment":[
                "Gravity": ARWorldTrackingConfiguration.WorldAlignment.gravity,
                "GravityAndHeading": ARWorldTrackingConfiguration.WorldAlignment.gravityAndHeading,
                "Camera": ARWorldTrackingConfiguration.WorldAlignment.camera
            ],
            "FillMode":[
                "Fill": SCNFillMode.fill,
                "Lines": SCNFillMode.lines
            ]
        ]
        return out
    }
    override class func requiresMainQueueSetup() -> Bool {
        return false
    }
    //MARK:ARSessionDelegate Methods
    func session(_ session: ARSession, didFailWithError error: Error) {
        //Is there someone paying attention to this?
        doSendEvent("ARSessionError", message: RCTJSErrorFromNSError(error))
    }
    //MARK:RCTEventEmitter Methods
    override func supportedEvents() -> [String]! {
        return [
        "ARSessionError",
        "RHDEvent",
        "RHDPlaneEvent",
        "RHDImageEvent"
        ]
    }
    func doSendEvent(_ key: String, message:Any?) {
        guard let l = listenedEvents[key], l > 0 else { return }
        sendEvent(withName: key, body: message)
    }
    var listenedEvents:[String:Int] = [:]
    override func addListener(_ eventName: String!) {
        super.addListener(eventName)
        if let val = listenedEvents[eventName] {
            listenedEvents[eventName] = val + 1
        } else {
            listenedEvents[eventName] = 1
        }
    }
    override func removeListeners(_ count: Double) {
        super.removeListeners(count)
        // Kill off all my listeners please
        listenedEvents = [:]
    }
    //MARK:ARAnchor delegate methods
    var baseNodes:[String:SCNNode] = [:]
    var anchors:[String:jsonType] = [:]
    var anchorObjects: [String: ARAnchor] = [:]
    func addAnchor(_ anchor: ARAnchor, withNode: SCNNode) {
        anchorObjects[anchor.identifier.uuidString] = anchor
        if let pa = anchor as? ARImageAnchor { addImageAnchor(pa, withNode: withNode) }
        if let pa = anchor as? ARPlaneAnchor { addPlaneAnchor(pa, withNode: withNode) }
    }
    func updateAnchor(_ anchor:ARAnchor, withNode: SCNNode) {
        if let pa = anchor as? ARImageAnchor { updateImageAnchor(pa, withNode: withNode)}
        if let pa = anchor as? ARPlaneAnchor { updatePlaneAnchor(pa, withNode: withNode)}
    }
    func removeAnchor(_ anchor: ARAnchor, withNode: SCNNode) {
        anchorObjects.removeValue(forKey: anchor.identifier.uuidString)
        if let pa = anchor as? ARImageAnchor { removeImageAnchor(pa, withNode: withNode)}
        if let pa = anchor as? ARPlaneAnchor { removePlaneAnchor(pa, withNode: withNode)}
    }
    func addPlaneAnchor(_ anchor: ARPlaneAnchor, withNode: SCNNode) {
        let id = anchor.identifier.uuidString
        let width = CGFloat(anchor.extent.x)
        let height = CGFloat(anchor.extent.z)
        baseNodes[id] = withNode
        let alignment:String = anchor.alignment == .horizontal ? "horizontal": "vertical"
        anchors[id] = ["type": "plane",  "plane": ["width": width, "height":height,"alignment": alignment ]];
        doSendEvent("RHDPlaneEvent", message: ["key": "planeAnchorAdded", "data": ["id": id, "action":"add", "anchor": anchors[id]]])
        fixOrphans()
    }
    func updatePlaneAnchor(_ anchor:ARPlaneAnchor, withNode: SCNNode) {
        let id = anchor.identifier.uuidString
        let width = CGFloat(anchor.extent.x)
        let height = CGFloat(anchor.extent.z)
        let alignment:String = anchor.alignment == .horizontal ? "horizontal": "vertical"
        anchors[id] = ["type": "plane",  "plane": ["width": width, "height":height,"alignment": alignment ]];
        doSendEvent("RHDPlaneEvent", message: ["key": "planeAnchorChanged", "data": ["id": id, "action": "update", "anchor": anchors[id]]])
        fixOrphans()
    }
    func removePlaneAnchor(_ anchor:ARPlaneAnchor, withNode: SCNNode) {
        let id = anchor.identifier.uuidString
        anchors.removeValue(forKey: id)
        baseNodes.removeValue(forKey: id)
        doSendEvent("RHDPlaneEvent", message: ["key": "planeAnchorRemoved", "data": ["id": id]])
    }
    var doDetectPlanes:Bool = false
    @objc func setPlaneDetection(_ detectPlanes: Bool, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        doDetectPlanes = detectPlanes
        setPlaneDetection()
        resolve(true)
    }
    func setPlaneDetection() {
        if(doDetectPlanes) {
            configuration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection(rawValue: 3)
        } else {
            configuration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection(rawValue: 0)
        }
        doResume()
    }
    @objc func getAnchors(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(anchors)
    }
    func addImageAnchor(_ anchor: ARImageAnchor, withNode: SCNNode) {
        guard let name = anchor.referenceImage.name else { return }
        let id = anchor.identifier.uuidString
        let w = anchor.referenceImage.physicalSize.width
        let h = anchor.referenceImage.physicalSize.height
        anchors[id] = ["type": "image", "name": name, "plane": ["width": w, "height":h]]
        baseNodes[id] = withNode
        doSendEvent("RHDImageEvent", message: ["key": "imageAnchorAdded", "data":["id":id, "action": "add", "anchor": anchors[id]!]])
    }
    
    func updateImageAnchor(_ anchor: ARImageAnchor, withNode: SCNNode) {
        let id = anchor.identifier.uuidString
        guard let name = anchors[id]?["image"] else { return }
        let w = anchor.referenceImage.physicalSize.width
        let h = anchor.referenceImage.physicalSize.height
        anchors[id] = ["type": "image", "name": name, "plane": ["width": w, "height":h]]
        doSendEvent("RHDImageEvent", message: ["key": "imageAnchorChanged", "data":["id":id, "action": "update", "anchor": anchors[id]!]])
    }
    func removeImageAnchor(_ anchor: ARImageAnchor, withNode: SCNNode) {
        let id = anchor.identifier.uuidString
        anchors.removeValue(forKey: id)
        baseNodes.removeValue(forKey: id)
        doSendEvent("RHDImageEvent", message: ["key": "imageAnchorRemoved", "data": ["id": id]])

    }
    @objc func removeAnchor(_ id:String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let s = session else {return}
        guard let a = anchorObjects[id] else { return }
        s.remove(anchor: a)
        anchorObjects.removeValue(forKey: id)
        anchors.removeValue(forKey: id)
        baseNodes.removeValue(forKey: id)
        resolve(true)
    }
    //MARK: Image Recognizer methods
    @objc func addRecognizerImage(_ url:String, name: String, width: Double, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        guard let fullURL = URL(string: url) else { reject("bad_url", "Could not resolve url " + url, nil); return}
        let path = fullURL.path
        guard let i = UIImage(contentsOfFile: path) else { reject("no_image", "could not get image from " + url, nil); return }
        guard let ci = CIImage(image: i) else { reject("no_ciimage", "Could not create Core Image value from " + url, nil); return}
        let context = CIContext(options: nil)
        guard let cg = context.createCGImage(ci, from: ci.extent) else { reject("no_cgimage", "Could not create CG Iamge from " + url, nil); return }
        let x = ARReferenceImage(cg, orientation: CGImagePropertyOrientation.up, physicalWidth: CGFloat(width))
        x.name = name
        detectionImages[name] = x
        setDetectionImages()
        resolve(name)
    }
    @objc func removeRecognizerImage(_ name: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        detectionImages.removeValue(forKey: name)
        setDetectionImages()
        resolve(true)
    }
    var detectionImages:[String: ARReferenceImage] = [:]
    var doDetectImages: Bool = false
    func setDetectionImages() {
        if(doDetectImages) {
            if(detectionImages.count > 0) {
                configuration.detectionImages = Set(detectionImages.values.map{$0})
            }
        } else {
            configuration.detectionImages = nil
        }
        doResume()
    }
    @objc func setImageDetection(_ doDetect:Bool, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        doDetectImages = doDetect
        setDetectionImages()
        resolve(true)
    }
    //MARK: Point of View methods
    var lastPosition:SCNVector3 = SCNVector3()
    var lastOrientation:SCNVector4 = SCNVector4()
    var sensitivity:Float = 0.05
    func updatePOV(_ pointOfView: SCNNode) {
        
        if abs(lastPosition.x - pointOfView.position.x) > sensitivity || abs(lastPosition.y - pointOfView.position.y) > sensitivity || abs(lastPosition.z - pointOfView.position.z) > sensitivity {
            doSendEvent("RHDEvent", message: ["key": "positionChanged", "data": ["position": vector3ToJson(pointOfView.position), "orientation": vector4ToJson(pointOfView.orientation)]])
            lastPosition = pointOfView.position
        }
    }
    @objc func setPOVSensitivity(_ newSensitivity:Double , resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        sensitivity = Float(newSensitivity)
        resolve(true)
    }
    @objc func getPOV(_ resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        resolve(lastPosition)
    }
    //MARK: World Tracking methods
    @objc func setWorldTracking(_ trackingMode: String, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) {
        var temp:ARWorldTrackingConfiguration.WorldAlignment
        switch(trackingMode) {
        case "camera":
            temp = .camera
        case "compass":
            temp = .gravityAndHeading
        default:
            temp = .gravity
        }
        if(temp != configuration.worldAlignment) {
            configuration.worldAlignment = temp
            doResume()
        }
    }
}
