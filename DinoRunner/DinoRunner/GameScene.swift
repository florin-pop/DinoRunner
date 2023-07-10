//
//  GameScene.swift
//  DinoRunner
//
//  Created by John Kuhn on 7/29/18.
//  Copyright © 2018 John Kuhn. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //nodes
    var gameNode: SKNode!
    var groundNode: SKNode!
    var backgroundNode: SKNode!
    var cactusNode: SKNode!
    var dinosaurNode: SKNode!
    
    //score
    var scoreNode: SKLabelNode!
    var resetInstructions: SKLabelNode!
    var score = 0 as Int
    var hitCactus = false
    var jumping = false
    var cactusPositionOnJumpStart: CGFloat?
    var cactusComingTowardsDino: SKNode? = nil
    
    //sound effects
    let jumpSound = SKAction.playSoundFileNamed("dino.assets/sounds/jump", waitForCompletion: false)
    let dieSound = SKAction.playSoundFileNamed("dino.assets/sounds/die", waitForCompletion: false)
    
    //sprites
    var dinoSprite: SKSpriteNode!
    
    //spawning vars
    var spawnRate = 1.5 as Double
    var timeSinceLastSpawn = 0.0 as Double
    
    //generic vars
    var groundHeight: CGFloat?
    var dinoYPosition: CGFloat?
    var groundSpeed = 300 as CGFloat
    
    //consts
    let dinoHopForce = 700 as Int
    let cloudSpeed = 50 as CGFloat
    let moonSpeed = 10 as CGFloat
    
    let background = 0 as CGFloat
    let foreground = 1 as CGFloat
    
    //collision categories
    let groundCategory = 1 << 0 as UInt32
    let dinoCategory = 1 << 1 as UInt32
    let cactusCategory = 1 << 2 as UInt32
    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = .white
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.8)
        
        //ground
        groundNode = SKNode()
        groundNode.zPosition = background
        createAndMoveGround()
        addCollisionToGround()
        
        //background elements
        backgroundNode = SKNode()
        backgroundNode.zPosition = background
        createMoon()
        createClouds()
        
        //dinosaur
        dinosaurNode = SKNode()
        dinosaurNode.zPosition = foreground
        createDinosaur()
        
        //cacti
        cactusNode = SKNode()
        cactusNode.zPosition = foreground
        
        //score
        score = 0
        scoreNode = SKLabelNode(fontNamed: "Arial")
        scoreNode.fontSize = 30
        scoreNode.zPosition = foreground
        scoreNode.text = "Score: 0"
        scoreNode.fontColor = SKColor.gray
        scoreNode.position = CGPoint(x: 150, y: 100)
        
        //reset instructions
        resetInstructions = SKLabelNode(fontNamed: "Arial")
        resetInstructions.fontSize = 50
        resetInstructions.text = "Tap to Restart"
        resetInstructions.fontColor = SKColor.white
        resetInstructions.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        //parent game node
        gameNode = SKNode()
        gameNode.addChild(groundNode)
        gameNode.addChild(backgroundNode)
        gameNode.addChild(dinosaurNode)
        gameNode.addChild(cactusNode)
        gameNode.addChild(scoreNode)
        gameNode.addChild(resetInstructions)
        self.addChild(gameNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameNode.speed < 1.0){
            resetGame()
            return
        }
        
        for _ in touches {
            if let groundPosition = dinoYPosition {
                if dinoSprite.position.y <= groundPosition && gameNode.speed > 0 {
                    dinoSprite.physicsBody?.applyImpulse(CGVector(dx: 0, dy: dinoHopForce))
                    run(jumpSound)
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if(gameNode.speed > 0) {
            if(currentTime - timeSinceLastSpawn > spawnRate) {
                timeSinceLastSpawn = currentTime
                spawnRate = Double.random(in: 1.0 ..< 3.5)
                spawnCactus()
            }
            updateCactusComingTowardsDino()
            
            if let groundPosition = dinoYPosition {
                if dinoSprite.position.y <= groundPosition {
                    if jumping && jumpedOverCactus() && !hitCactus {
                        score += 1
                        scoreNode.text = "Score: \(score)"
                    }
                    jumping = false
                } else {
                    jumping = true
                    setCactusPositionOnJumpStart()
                }
            }
            
            if cactusMovedPassedDino() {
                resetCactusComingTowardsDino()
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if(hitCactus(contact)) {
//            run(dieSound)
//            gameOver()
            hitCactus = true
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        if(hitCactus(contact)) {
            hitCactus = false
        }
    }
    
    func jumpedOverCactus() -> Bool {
        if let cactusPositionOnJumpStart = cactusPositionOnJumpStart, cactusPositionOnJumpStart > (dinoSprite.position.x + dinoSprite.frame.width) {
            if let cactusComingTowardsDino = cactusComingTowardsDino {
                if (cactusComingTowardsDino.position.x + cactusComingTowardsDino.frame.width) < dinoSprite.position.x {
                    return true
                }
            }
        }
        return false
    }
    
    func updateCactusComingTowardsDino() {
        if cactusComingTowardsDino == nil {
            cactusComingTowardsDino = cactusNode.children.first { $0.position.x > dinoSprite.position.x }
        }
    }
    
    func resetCactusComingTowardsDino() {
        self.cactusPositionOnJumpStart = nil
        self.cactusComingTowardsDino = nil
    }
    
    func setCactusPositionOnJumpStart() {
        if cactusPositionOnJumpStart == nil {
            cactusPositionOnJumpStart = cactusComingTowardsDino?.position.x ?? nil
        }
    }
    
    func cactusMovedPassedDino() -> Bool {
        if let cactusComingTowardsDino = cactusComingTowardsDino, !jumping {
            if (cactusComingTowardsDino.position.x + cactusComingTowardsDino.frame.width) < dinoSprite.position.x {
                return true
            }
        }
        return false
    }
    
    func hitCactus(_ contact: SKPhysicsContact) -> Bool {
        return contact.bodyA.categoryBitMask & cactusCategory == cactusCategory ||
            contact.bodyB.categoryBitMask & cactusCategory == cactusCategory
    }
    
    func resetGame() {
        gameNode.speed = 1.0
        timeSinceLastSpawn = 0.0
        groundSpeed = 500
        score = 0
        
        cactusNode.removeAllChildren()
        
        resetInstructions.fontColor = SKColor.white
        
        let dinoTexture1 = SKTexture(imageNamed: "dino.assets/dinosaurs/dinoRight")
        let dinoTexture2 = SKTexture(imageNamed: "dino.assets/dinosaurs/dinoLeft")
        dinoTexture1.filteringMode = .nearest
        dinoTexture2.filteringMode = .nearest
        
        let runningAnimation = SKAction.animate(with: [dinoTexture1, dinoTexture2], timePerFrame: 0.12)
        
        dinoSprite.position = CGPoint(x: self.frame.size.width * 0.15, y: dinoYPosition!)
        dinoSprite.run(SKAction.repeatForever(runningAnimation))
    }
    
    func gameOver() {
        gameNode.speed = 0.0
        
        resetInstructions.fontColor = SKColor.gray
        
        let deadDinoTexture = SKTexture(imageNamed: "dino.assets/dinosaurs/dinoDead")
        deadDinoTexture.filteringMode = .nearest
        
        dinoSprite.removeAllActions()
        dinoSprite.texture = deadDinoTexture
    }
    
    func createAndMoveGround() {
        let screenWidth = self.frame.size.width
        
        //ground texture
        let groundTexture = SKTexture(imageNamed: "dino.assets/landscape/ground")
        groundTexture.filteringMode = .nearest
        
        let homeButtonPadding = 50.0 as CGFloat
        groundHeight = groundTexture.size().height + homeButtonPadding
        
        //ground actions
        let moveGroundLeft = SKAction.moveBy(x: -groundTexture.size().width,
                                             y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0.0, duration: 0.0)
        let groundLoop = SKAction.sequence([moveGroundLeft, resetGround])
        
        //ground nodes
        let numberOfGroundNodes = 1 + Int(ceil(screenWidth / groundTexture.size().width))
        
        for i in 0 ..< numberOfGroundNodes {
            let node = SKSpriteNode(texture: groundTexture)
            node.anchorPoint = CGPoint(x: 0.0, y: 0.0)
            node.position = CGPoint(x: CGFloat(i) * groundTexture.size().width, y: groundHeight!)
            groundNode.addChild(node)
            node.run(SKAction.repeatForever(groundLoop))
        }
    }
    
    func addCollisionToGround() {
        let groundContactNode = SKNode()
        groundContactNode.position = CGPoint(x: 0, y: groundHeight! - 30)
        groundContactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width * 3,
                                                                          height: groundHeight!))
        groundContactNode.physicsBody?.friction = 0.0
        groundContactNode.physicsBody?.isDynamic = false
        groundContactNode.physicsBody?.categoryBitMask = groundCategory
        
        groundNode.addChild(groundContactNode)
    }
    
    func createMoon() {
        //texture
        let moonTexture = SKTexture(imageNamed: "dino.assets/landscape/moon")
        let moonScale = 3.0 as CGFloat
        moonTexture.filteringMode = .nearest
        
        //moon sprite
        let moonSprite = SKSpriteNode(texture: moonTexture)
        moonSprite.setScale(moonScale)
        //add to scene
        backgroundNode.addChild(moonSprite)
        
        //animate the moon
        animateMoon(sprite: moonSprite, textureWidth: moonTexture.size().width * moonScale)
    }
    
    func animateMoon(sprite: SKSpriteNode, textureWidth: CGFloat) {
        let screenWidth = self.frame.size.width
        let screenHeight = self.frame.size.height
        
        let distanceOffscreen = 50.0 as CGFloat // want to start the moon offscreen
        let distanceBelowTop = 150 as CGFloat
        
        //moon actions
        let moveMoon = SKAction.moveBy(x: -screenWidth - textureWidth - distanceOffscreen,
                                       y: 0.0, duration: TimeInterval(screenWidth / moonSpeed))
        let resetMoon = SKAction.moveBy(x: screenWidth + distanceOffscreen, y: 0.0, duration: 0)
        let moonLoop = SKAction.sequence([moveMoon, resetMoon])
        
        sprite.position = CGPoint(x: screenWidth + distanceOffscreen, y: screenHeight - distanceBelowTop)
        sprite.run(SKAction.repeatForever(moonLoop))
    }
    
    func createClouds() {
        //texture
        let cloudTexture = SKTexture(imageNamed: "dino.assets/landscape/cloud")
        let cloudScale = 3.0 as CGFloat
        cloudTexture.filteringMode = .nearest
        
        //clouds
        let numClouds = 3
        for i in 0 ..< numClouds {
            //create sprite
            let cloudSprite = SKSpriteNode(texture: cloudTexture)
            cloudSprite.setScale(cloudScale)
            //add to scene
            backgroundNode.addChild(cloudSprite)
            
            //animate the cloud
            animateCloud(cloudSprite, cloudIndex: i, textureWidth: cloudTexture.size().width * cloudScale)
        }
    }
    
    func animateCloud(_ sprite: SKSpriteNode, cloudIndex i: Int, textureWidth: CGFloat) {
        let screenWidth = self.frame.size.width
        let screenHeight = self.frame.size.height
        
        let cloudOffscreenDistance = (screenWidth / 3.0) * CGFloat(i) + 100 as CGFloat
        let cloudYPadding = 50 as CGFloat
        let cloudYPosition = screenHeight - (CGFloat(i) * cloudYPadding) - 200
        
        let distanceToMove = screenWidth + cloudOffscreenDistance + textureWidth
        
        //actions
        let moveCloud = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(distanceToMove / cloudSpeed))
        let resetCloud = SKAction.moveBy(x: distanceToMove, y: 0.0, duration: 0.0)
        let cloudLoop = SKAction.sequence([moveCloud, resetCloud])
        
        sprite.position = CGPoint(x: screenWidth + cloudOffscreenDistance, y: cloudYPosition)
        sprite.run(SKAction.repeatForever(cloudLoop))
    }
    
    func createDinosaur() {
        let screenWidth = self.frame.size.width
        let dinoScale = 4.0 as CGFloat
        
        //textures
        let dinoTexture1 = SKTexture(imageNamed: "dino.assets/dinosaurs/dinoRight")
        let dinoTexture2 = SKTexture(imageNamed: "dino.assets/dinosaurs/dinoLeft")
        dinoTexture1.filteringMode = .nearest
        dinoTexture2.filteringMode = .nearest
        
        let runningAnimation = SKAction.animate(with: [dinoTexture1, dinoTexture2], timePerFrame: 0.12)
        
        dinoSprite = SKSpriteNode()
        dinoSprite.size = dinoTexture1.size()
        dinoSprite.setScale(dinoScale)
        dinosaurNode.addChild(dinoSprite)
        
        let physicsBox = CGSize(width: dinoTexture1.size().width * dinoScale,
                                height: dinoTexture1.size().height * dinoScale)
        
        dinoSprite.physicsBody = SKPhysicsBody(rectangleOf: physicsBox)
        dinoSprite.physicsBody?.isDynamic = true
        dinoSprite.physicsBody?.mass = 1.0
        dinoSprite.physicsBody?.categoryBitMask = dinoCategory
        dinoSprite.physicsBody?.contactTestBitMask = cactusCategory
        dinoSprite.physicsBody?.collisionBitMask = groundCategory
        
        dinoYPosition = getGroundHeight() + dinoTexture1.size().height * dinoScale
        dinoSprite.position = CGPoint(x: screenWidth * 0.15, y: dinoYPosition!)
        dinoSprite.run(SKAction.repeatForever(runningAnimation))
    }
    
    func spawnCactus() {
//        let cactusTextures = ["cactus1", "cactus2", "cactus3", "doubleCactus", "tripleCactus"]
        let cactusTextures = ["cactus1"]
        let cactusScale = 3.0 as CGFloat
        
        //texture
        let cactusTexture = SKTexture(imageNamed: "dino.assets/cacti/" + cactusTextures.randomElement()!)
        cactusTexture.filteringMode = .nearest
        
        //sprite
        let cactusSprite = SKSpriteNode(texture: cactusTexture)
        cactusSprite.setScale(cactusScale)
        
        //physics
        let contactBox = CGSize(width: cactusTexture.size().width * cactusScale,
                                height: cactusTexture.size().height * cactusScale)
        cactusSprite.physicsBody = SKPhysicsBody(rectangleOf: contactBox)
        cactusSprite.physicsBody?.isDynamic = true
        cactusSprite.physicsBody?.mass = 1.0
        cactusSprite.physicsBody?.categoryBitMask = cactusCategory
        cactusSprite.physicsBody?.contactTestBitMask = dinoCategory
        cactusSprite.physicsBody?.collisionBitMask = groundCategory
        
        //add to scene
        cactusNode.addChild(cactusSprite)
        //animate
        animateCactus(sprite: cactusSprite, texture: cactusTexture)
    }
    
    func animateCactus(sprite: SKSpriteNode, texture: SKTexture) {
        let screenWidth = self.frame.size.width
        let distanceOffscreen = 50.0 as CGFloat
        let distanceToMove = screenWidth + distanceOffscreen + texture.size().width
        
        //actions
        let moveCactus = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let removeCactus = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([moveCactus, removeCactus])
        
        sprite.position = CGPoint(x: distanceToMove, y: getGroundHeight() + texture.size().height)
        sprite.run(moveAndRemove)
    }
    
    func getGroundHeight() -> CGFloat {
        if let gHeight = groundHeight {
            return gHeight
        } else {
            print("Ground size wasn't previously calculated")
            exit(0)
        }
    }
    
}
