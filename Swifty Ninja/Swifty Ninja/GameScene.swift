//
//  GameScene.swift
//  Swifty Ninja
//
//  Created by Timothy on 30/05/2023.
//

import AVFoundation
import SpriteKit
import GameplayKit

// all the ways we can create an enemy!
enum SequenceType: CaseIterable {
    case oneNoBomb, one, twoWithOneBomb, two, three, four, chain, fastChain
}

enum ForceBomb {
    case never, always, random
}

class GameScene: SKScene {
    var gameScore: SKLabelNode!
    var score = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    
    var livesImages = [SKSpriteNode]()
    var lives = 3
    
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    
    var isSwooshSoundActive = false
    var bombSoundEffect: AVAudioPlayer?
    
    var gameOver: SKSpriteNode!
    
    // store swipe points
    var activeSlicePoints = [CGPoint]()
    
    // track enemies that are currently active in the scene
    var activeEnemies = [SKSpriteNode]()
    
    // The popupTime property is the amount of time to wait between the last enemy being destroyed and a new one being created.
    var popupTime = 0.9
    // The sequence property is an array of our SequenceType enum that defines what enemies to create.
    var sequence = [SequenceType]()
    // The sequencePosition property is where we are right now in the game.
    var sequencePosition = 0
    // The chainDelay property is how long to wait before creating a new enemy when the sequence type is .chain or .fastChain. Enemy chains don't wait until the previous enemy is offscreen before creating a new one, so it's like throwing five enemies quickly but with a small delay between each one.
    var chainDelay = 3.0
    // The nextSequenceQueued property is used so we know when all the enemies are destroyed and we're ready to create more.
    var nextSequenceQueued = true
    
    var isGameEnded = false
    
    func createEnemy(forceBomb: ForceBomb = .random) {
        let enemy: SKSpriteNode
        
        var enemyType = Int.random(in: 0...6)
        
        if forceBomb == .never {
            enemyType = 1
        } else if forceBomb == .always {
            enemyType = 0
        }
        
        if enemyType == 0 {
            // bomb code
            // 1. Create a new SKSpriteNode that will hold the fuse and the bomb image as children, setting its Z position to be 1.
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            // 2. Create the bomb image, name it "bomb", and add it to the container.
            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)
            
            // 3. If the bomb fuse sound effect is playing, stop it and destroy it.
            if bombSoundEffect != nil {
                bombSoundEffect?.stop()
                bombSoundEffect = nil
            }
            
            // 4. Create a new bomb fuse sound effect, then play it.
            if let path = Bundle.main.url(forResource: "sliceBombFuse", withExtension: "caf") {
                if let sound = try?  AVAudioPlayer(contentsOf: path) {
                    bombSoundEffect = sound
                    sound.play()
                }
            }
            
            // 5. Create a particle emitter node, position it so that it's at the end of the bomb image's fuse, and add it to the container.
            if let emitter = SKEmitterNode(fileNamed: "sliceFuse") {
                emitter.position = CGPoint(x: 76, y: 64)
                enemy.addChild(emitter)
            }
        } else {
            enemy = SKSpriteNode(imageNamed: "penguin")
            run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }
        
        let minXPosition = 64
        let maxXPosition = 960
        let randomYPosition = -128
        let minAngularVelocity: CGFloat = -3
        let maxAngularVelocity: CGFloat = 3
        let quarterOfScreen: CGFloat = 256
        let halfOfScreen: CGFloat = 512
        let threeQuartersOfScreen: CGFloat = 768
        let minOuterXVelocity = 8
        let maxXQuarterVelocity = 15
        let minInnerXVelocity = 3
        let maxInnerXVelocity = 5
        let minYVelocity = 24
        let maxYVelocity = 32
        let velocityMultiplier = 40
        let enemyPhysicsBodyRadius: CGFloat = 64
        
        // position code
        // The only thing that might catch you out in the actual code is my use of magic numbers, which is what programmers call seemingly random (but actually important) numbers appearing in code. Need to replace them with actual constants later.
        // 1. Give the enemy a random position off the bottom edge of the screen.
        let randomPosition = CGPoint(x: Int.random(in: minXPosition...maxXPosition), y: randomYPosition)
        enemy.position = randomPosition
        
        // 2. Create a random angular velocity, which is how fast something should spin.
        let randomAngularVelocity = CGFloat.random(in: minAngularVelocity...maxAngularVelocity)
        let randomXVelocity: Int
        
        // 3. Create a random X velocity (how far to move horizontally) that takes into account the enemy's position.
        if randomPosition.x < quarterOfScreen {
            randomXVelocity = Int.random(in: minOuterXVelocity...maxXQuarterVelocity)
        } else if randomPosition.x < halfOfScreen {
            randomXVelocity = Int.random(in: minInnerXVelocity...maxInnerXVelocity)
        } else if randomPosition.x < threeQuartersOfScreen {
            randomXVelocity = -Int.random(in: minInnerXVelocity...maxInnerXVelocity)
        } else {
            randomXVelocity = -Int.random(in: minOuterXVelocity...maxXQuarterVelocity)
        }
        
        // 4. Create a random Y velocity just to make things fly at different speeds.
        let randomYVelocity = Int.random(in: minYVelocity...maxYVelocity)
        
        // 5. Give all enemies a circular physics body where the collisionBitMask is set to 0 so they don't collide.
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemyPhysicsBodyRadius)
        enemy.physicsBody?.velocity = CGVector(dx: randomXVelocity * velocityMultiplier, dy: randomYVelocity * velocityMultiplier)
        enemy.physicsBody?.angularVelocity = randomAngularVelocity
        enemy.physicsBody?.collisionBitMask = 0
        
        addChild(enemy)
        activeEnemies.append(enemy)
    }
    
    // That looks like a massive method, I know, but in reality it's just the same thing being called in different ways. The interesting parts are the .chain and .fastChain cases, and also I want to explain in more detail the nextSequenceQueued property.
    // Each sequence in our array creates one or more enemies, then waits for them to be destroyed before continuing. Enemy chains are different: they create five enemies with a short break between, and don't wait for each one to be destroyed before continuing.
    // To handle these chains, we have calls to asyncAfter() with a timer value. If we assume for a moment that chainDelay is 10 seconds, then:
    
    // That makes chainDelay / 10.0 equal to 1 second.
    // That makes chainDelay / 10.0 * 2 equal to 2 seconds.
    // That makes chainDelay / 10.0 * 3 equal to three seconds.
    // That makes chainDelay / 10.0 * 4 equal to four seconds.

    // So, it spreads out the createEnemy() calls quite neatly.

    // The nextSequenceQueued property is more complicated. If it's false, it means we don't have a call to tossEnemies() in the pipeline waiting to execute. It gets set to true only in the gap between the previous sequence item finishing and tossEnemies() being called. Think of it as meaning, "I know there aren't any enemies right now, but more will come shortly."
    func tossEnemies() {
        if isGameEnded {
            return
        }
        
        popupTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02

        let sequenceType = sequence[sequencePosition]

        switch sequenceType {
        case .oneNoBomb:
            createEnemy(forceBomb: .never)

        case .one:
            createEnemy()

        case .twoWithOneBomb:
            createEnemy(forceBomb: .never)
            createEnemy(forceBomb: .always)

        case .two:
            createEnemy()
            createEnemy()

        case .three:
            createEnemy()
            createEnemy()
            createEnemy()

        case .four:
            createEnemy()
            createEnemy()
            createEnemy()
            createEnemy()

        case .chain:
            createEnemy()

            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 2)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 3)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 4)) { [weak self] in self?.createEnemy() }

        case .fastChain:
            createEnemy()

            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 2)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 3)) { [weak self] in self?.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 4)) { [weak self] in self?.createEnemy() }
        }

        sequencePosition += 1
        nextSequenceQueued = false
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        // I'm also telling the physics world to adjust its speed downwards, which causes all movement to happen at a slightly slower rate.
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        //  The default gravity of our physics world is -0.98, which is roughly equivalent to Earth's gravity. I'm using a slightly lower value so that items stay up in the air a bit longer.
        physicsWorld.speed = 0.85
        
        gameOver = nil
        
        createScore()
        createLives()
        createSlices()
        
        // That code fills the sequence array with seven pre-written sequences to help players warm up to how the game works, then adds 1001 (the ... operator means “up to and including”) random sequence types to fill up the game. Finally, it triggers the initial enemy toss after two seconds.
        sequence = [.oneNoBomb, .oneNoBomb, .twoWithOneBomb, .twoWithOneBomb, .three, .one, .chain]
        
        for _ in 0...1000 {
            if let nextSequence = SequenceType.allCases.randomElement() {
                sequence.append(nextSequence)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.tossEnemies()
        }
    }
    
    func createScore() {
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 48
        addChild(gameScore)

        gameScore.position = CGPoint(x: 8, y: 8)
        score = 0
    }
    
    func createLives() {
        for i in 0 ..< 3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)

            // adding the lives images to the livesImages array, which is done so that we can cross off lives when the player loses
            livesImages.append(spriteNode)
        }
    }
    
    func createSlices() {
        // Track all player moves on the screen, recording an array of all their swipe points.
        // Draw two slice shapes, one in white and one in yellow to make it look like there's a hot glow.
        // Use the zPosition property to make sure the slices go above everything else in the game.
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 3
        
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        
        activeSliceFG.strokeColor = UIColor.white
        activeSliceFG.lineWidth = 5
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        // 1. Remove all existing points in the activeSlicePoints array, because we're starting fresh.
        activeSlicePoints.removeAll(keepingCapacity: true)
        
        // 2. Get the touch location and add it to the activeSlicePoints array.
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        
        // 3. Call the (as yet unwritten) redrawActiveSlice() method to clear the slice shapes.
        redrawActiveSlice()
        
        // 4. Remove any actions that are currently attached to the slice shapes. This will be important if they are in the middle of a fadeOut(withDuration:) action.
        activeSliceBG.removeAllActions()
        activeSliceFG.removeAllActions()
        
        // 5. Set both slice shapes to have an alpha value of 1 so they are fully visible.
        activeSliceBG.alpha = 1
        activeSliceFG.alpha = 1
    }
    
    // All the touchesMoved() method needs to do is figure out where in the scene the user touched, add that location to the slice points array, then redraw the slice shape, so that's easy enough:
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameEnded {
            return
        }
        
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        if !isSwooshSoundActive {
            playSwooshSound()
        }
        
        let nodesAtPoint = nodes(at: location)
        
        for case let node as SKSpriteNode in nodesAtPoint {
            if node.name == "enemy" {
                // destroy penguin in these steps
                // 1. Create a particle effect over the penguin.
                if let emitter = SKEmitterNode(fileNamed: "sliceHitEnemy") {
                    emitter.position = node.position
                    addChild(emitter)
                }
                
                // 2. Clear its node name so that it can't be swiped repeatedly.
                node.name = ""
                
                // 3. Disable the isDynamic of its physics body so that it doesn't carry on falling.
                node.physicsBody?.isDynamic = false
                
                // 4. Make the penguin scale out and fade out at the same time.
                let scaleOut = SKAction.scale(to: 0.001, duration:0.2)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let group = SKAction.group([scaleOut, fadeOut])

                
                // 5. After making the penguin scale out and fade out, we should remove it from the scene.
                let seq = SKAction.sequence([group, .removeFromParent()])
                node.run(seq)
                
                // 6. +1 to the player's score.
                score += 1
                
                // 7. Remove the enemy from our activeEnemies array.
                if let index = activeEnemies.firstIndex(of: node) {
                    activeEnemies.remove(at: index)
                }
                
                // 8. Play a sound so the player knows they hit the penguin.
                run(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))
            } else if node.name == "bomb" {
                // destroy bomb
                guard let bombContainer = node.parent as? SKSpriteNode else {
                    continue
                }
                
                if let emitter = SKEmitterNode(fileNamed: "sliceHitBomb") {
                    emitter.position = node.position
                    addChild(emitter)
                }
                
                node.name = ""
                bombContainer.physicsBody?.isDynamic = false
                
                let scaleOut = SKAction.scale(to: 0.001, duration:0.2)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                let seq = SKAction.sequence([group, .removeFromParent()])
                bombContainer.run(seq)

                if let index = activeEnemies.firstIndex(of: bombContainer) {
                    activeEnemies.remove(at: index)
                }

                run(SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false))
                endGame(triggeredByBomb: true)
            }
        }
    }
    
    // When the user finishes touching the screen, touchesEnded() will be called. I'm going to make this method fade out the slice shapes over a quarter of a second. We could remove them immediately but that looks ugly, and leaving them sitting there for no reason would rather destroy the effect.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSliceBG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSliceFG.run(SKAction.fadeOut(withDuration: 0.25))
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        var bombCount = 0
        
        for node in activeEnemies {
            if node.name == "bombContainer" {
                bombCount += 1
                break
            }
        }
        
        if bombCount == 0 {
            // no bombs = stop fuse sound!
            bombSoundEffect?.stop()
            bombSoundEffect = nil
        }
        
        // 1. If we have active enemies, we loop through each of them.
        if activeEnemies.count > 0 {
            for (index, node) in activeEnemies.enumerated().reversed() {
                // If any enemy is at or lower than Y position -140, we remove it from the game and our activeEnemies array.
                if node.position.y < -140 {
                    node.removeFromParent()
                    
                    if node.name == "enemy" {
                        node.name = ""
                        subtractLife()
                        
                        node.removeFromParent()
                        activeEnemies.remove(at: index)
                    } else if node.name == "bombContainer" {
                        node.name = ""
                        node.removeFromParent()
                        activeEnemies.remove(at: index)
                    }
                }
            }
        } else {
            // If we don't have any active enemies and we haven't already queued the next enemy sequence, we schedule the next enemy sequence and set nextSequenceQueued to be true.
            if !nextSequenceQueued {
                DispatchQueue.main.asyncAfter(deadline: .now() + popupTime) {[weak self] in
                    self?.tossEnemies()
                }
                
                nextSequenceQueued = true
            }
        }
    }
    
    // To make this work, you're going to need to know that an SKShapeNode object has a property called path which describes the shape we want to draw. When it's nil, there's nothing to draw; when it's set to a valid path, that gets drawn with the SKShapeNode's settings. SKShapeNode expects you to use a data type called CGPath, but we can easily create that from a UIBezierPath.
    // Drawing a complex path using UIBezierPath is a cinch: we'll use its move(to:) method to position the start of our lines, then loop through our activeSlicePoints array and call the path's addLine(to:) method for each point.
    // To stop the array storing more than 12 slice points, we’re going new method called removeFirst(), which lets us remove a certain number of items from the start of an array. In this case we know we want at most 12, so we can subtract 12 from our current count to see how many excess we have, and pass that to removeFirst().
    func redrawActiveSlice() {
        // 1. If we have fewer than two points in our array, we don't have enough data to draw a line so it needs to clear the shapes and exit the method.
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        // 2. If we have more than 12 slice points in our array, we need to remove the oldest ones until we have at most 12 – this stops the swipe shapes from becoming too long.
        if activeSlicePoints.count > 12 {
            activeSlicePoints.removeFirst(activeSlicePoints.count - 12)
        }
        
        // 3. It needs to start its line at the position of the first swipe point, then go through each of the others drawing lines to each point.
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        
        for i in 1..<activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }
        
        // 4. Finally, it needs to update the slice shape paths so they get drawn using their designs – i.e., line width and color.
        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath
    }
    
    // The playSwooshSound() method needs to set isSwooshSoundActive to be true (so that no other swoosh sounds are played until we're ready), play one of the three sounds, then when the sound has finished set isSwooshSoundActive to be false again so that another swoosh sound can play.
    func playSwooshSound() {
        isSwooshSoundActive = true
        
        let randomNumber = Int.random(in: 1...3)
        let soundName = "swoosh\(randomNumber).caf"
        
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        run(swooshSound) {[weak self] in
            self?.isSwooshSoundActive = false
        }
    }
    // The subtractLife() method, which is called when a penguin falls off the screen without being sliced. It needs to subtract 1 from the lives property that we created what seems like years ago, update the images in the livesImages array so that the correct number are crossed off, then end the game if the player is out of lives.
    // To make it a bit clearer that something bad has happened, we're also going to add playing a sound and animate the life being lost – we'll set the X and Y scale of the life being lost to 1.3, then animate it back down to 1.0.
    func subtractLife() {
        lives -= 1
        
        run(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))
        
        var life: SKSpriteNode
        
        if lives == 2 {
            life = livesImages[0]
        } else if lives == 1 {
            life = livesImages[1]
        } else {
            life = livesImages[2]
            endGame(triggeredByBomb: false)
        }
        
        // use SKTexture to modify the contents of a sprite node without having to recreate it
        life.texture = SKTexture(imageNamed: "sliceLifeGone")
        
        life.xScale = 1.3
        life.yScale = 1.3
        life.run(SKAction.scale(to: 1, duration:0.1))
    }
    
    func endGame(triggeredByBomb: Bool) {
        if isGameEnded {
            return
        }
        
        isGameEnded = true
        physicsWorld.speed = 0
        isUserInteractionEnabled = false
        
        bombSoundEffect?.stop()
        bombSoundEffect = nil
        
        if triggeredByBomb {
            livesImages[0].texture = SKTexture(imageNamed: "sliceLifeGone")
            livesImages[1].texture = SKTexture(imageNamed: "sliceLifeGone")
            livesImages[2].texture = SKTexture(imageNamed: "sliceLifeGone")
        }
        
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score: \(score)"
        gameScore.fontSize = 48
        gameOver.position = CGPoint(x: 512, y: 384)
        gameOver.zPosition = 1
        addChild(gameOver)
    }
}
