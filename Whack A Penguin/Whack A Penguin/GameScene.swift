//
//  GameScene.swift
//  Whack A Penguin
//
//  Created by Timothy on 23/05/2023.
//

import SpriteKit

class GameScene: SKScene {
    var gameScore: SKLabelNode!
    // An array in which we can store all our slots for referencing later
    var slots = [WhackSlot]()
    var popUpTime = 0.85
    var numRounds = 0
    
    var score = 0 {
        // Right now we have a property called score that is set to 0 when the game is created and increments by one whenever an answer is found. But we don't do anything with that score, so our score label is never updated.
        // One solution to this problem is to use something like scoreLabel.text = "Score: \(score)" whenever the score value is changed, and that's perfectly fine to begin with. But what happens if you're changing the score from several places? You need to keep all the code synchronized, which is unpleasant.
        // Swift’s solution is property observers, which let you execute code whenever a property has changed. To make them work, we use either didSet to execute code when a property has just been set, or willSet to execute code before a property has been set.
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "whackBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score: 0"
        gameScore.position = CGPoint(x: 8, y: 8)
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 48
        addChild(gameScore)
        
        // Four loops, one for each row.
        for i in 0..<5 {
            createSlot(at: CGPoint(x: 100 + (i * 170), y: 410))
        }
        
        for i in 0..<4 {
            createSlot(at: CGPoint(x: 100 + (i * 170), y: 320))
        }
        
        for i in 0..<5 {
            createSlot(at: CGPoint(x: 100 + (i * 170), y: 230))
        }
        
        for i in 0..<4 {
            createSlot(at: CGPoint(x: 100 + (i * 170), y: 140))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.createEnemy()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        
        for node in tappedNodes {
            guard let whackSlot = node.parent?.parent as? WhackSlot else {
                continue
            }
            
            if !whackSlot.isVisible {
                continue
            }
            
            if whackSlot.isHit {
                continue
            }
            
            whackSlot.hit()
            
            if node.name == "charFriend" {
                // they shouldn't have whacked this penguin
                score -= 5
                
                run(SKAction.playSoundFileNamed("whackBad.caf", waitForCompletion: false))
            } else if node.name == "charEnemy" {
                // they should have whacked this one!
                whackSlot.charNode.xScale = 0.85
                whackSlot.charNode.yScale = 0.85
                
                score += 1
                
                run(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))
            }
        }
    }
    
    // A createSlot(at:) method that handles slot creation.
    func createSlot(at position: CGPoint) {
        let slot = WhackSlot()
        slot.configure(at: position)
        addChild(slot)
        slots.append(slot)
    }
    
    func createEnemy() {
        numRounds += 1
        
        if numRounds >= 30 {
            for slot in slots {
                slot.hide()
            }
            
            let gameOver = SKSpriteNode(imageNamed: "gameOver")
            gameScore = SKLabelNode(fontNamed: "Chalkduster")
            gameScore.text = "Score: \(score)"
            gameScore.fontSize = 48
            gameOver.position = CGPoint(x: 512, y: 384)
            gameOver.zPosition = 1
            addChild(gameOver)
            
            run(SKAction.playSoundFileNamed("whackBad.caf", waitForCompletion: false))
            
            return
        }
        
        popUpTime *= 0.991
        
        slots.shuffle()
        slots[0].show(hideTime: popUpTime)
        
        if Int.random(in: 0...12) > 4 {
            slots[1].show(hideTime: popUpTime)
        }
        
        if Int.random(in: 0...12) > 8 {
            slots[2].show(hideTime: popUpTime)
        }
        
        if Int.random(in: 0...12) > 10 {
            slots[3].show(hideTime: popUpTime)
        }
        
        if Int.random(in: 0...12) > 11 {
            slots[4].show(hideTime: popUpTime)
        }
        
        let minDelay = popUpTime / 2.0
        let maxDelay = popUpTime * 2
        let delay = Double.random(in: minDelay...maxDelay)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.createEnemy()
        }
    }
}
