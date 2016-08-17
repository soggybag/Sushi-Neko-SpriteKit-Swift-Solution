//
//  GameScene.swift
//  Sushi Neko
//
//  Created by Martin Walsh on 05/04/2016.
//  Copyright (c) 2016 Make School. All rights reserved.
//

import SpriteKit

/* Tracking enum for use with character and sushi side */
enum Side {
    case left, right, none
}


/* Tracking enum for game state */
enum GameState {
    case title, ready, playing, gameOver
}


class GameScene: SKScene {
    
    /* Game objects */
    var character: Character!
    var sushiBasePiece: SushiPiece!
    var playButton: MSButtonNode!
    var healthBar: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    
    /* Sushi tower array */
    var sushiTower: [SushiPiece] = []
    
    /* Game management */
    var state: GameState = .title
    
    var health: CGFloat = 1.0 {
        didSet {
            /* Cap Health */
            if health > 1.0 { health = 1.0 }
            
            /* Scale health bar between 0.0 -> 1.0 e.g 0 -> 100% */
            healthBar.xScale = health
        }
    }
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = String(score)
        }
    }
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        
        /* Connect game objects */
        character = childNode(withName: "character") as! Character
        sushiBasePiece = childNode(withName: "sushiBasePiece") as! SushiPiece
        
        /* UI game objects */
        playButton = childNode(withName: "playButton") as! MSButtonNode
        healthBar = childNode(withName: "healthBar") as! SKSpriteNode
        scoreLabel = childNode(withName: "scoreLabel") as! SKLabelNode
        
        /* Setup play button selection handler */
        playButton.selectedHandler = {
            
            /* Start game */
            self.state = .ready
        }
        
        /* Setup chopstick connections */
        sushiBasePiece.connectChopsticks()
        
        /* Manually stack the start of the tower */
        addTowerPiece(.none)
        addTowerPiece(.right)
        
        /* Randomize tower to just outside of the screen */
        addRandomPieces(10)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* Game not ready to play */
        if state == .gameOver || state == .title { return }
        
        /* Game begins on first touch */
        if state == .ready {
            state = .playing
        }
        
        /* We only need a single touch here */
        let touch = touches.first!
            
        /* Get touch position in scene */
        let location = touch.location(in: self)
        
        /* Was touch on left/right hand side of screen? */
        if location.x > size.width / 2 {
            character.side = .right
        } else {
            character.side = .left
        }
        
        /* Grab sushi piece on top of the base sushi piece, it will always be 'first' */
        let firstPiece = sushiTower.first as SushiPiece!
        
        /* Check character side against sushi piece side (this is our death collision check)*/
        if character.side == firstPiece?.side {
            
            /* Drop all the sushi pieces down a place (visually) */
            for sushiPiece in sushiTower {
                sushiPiece.run(SKAction.move(by: CGVector(dx: 0, dy: -55), duration: 0.10))
            }
            
            gameOver()
            
            /* No need to continue as player dead */
            return
        }
        
        /* Increment Health */
        health += 0.1
        
        /* Increment Score */
        score += 1
        
        /* Remove from sushi tower array */
        sushiTower.removeFirst()
        
        /* Animate the punched sushi piece */
        firstPiece?.flip(character.side)
        
        /* Add a new sushi piece to the top of the sushi tower */
        addRandomPieces(1)
        
        /* Drop all the sushi pieces down one place */
        for sushiPiece in sushiTower {
            sushiPiece.run(SKAction.move(by: CGVector(dx: 0, dy: -55), duration: 0.10))
            
            /* Reduce zPosition to stop zPosition climbing over UI */
            sushiPiece.zPosition -= 1
        }
    }
    
    func addTowerPiece(_ side: Side) {
        /* Add a new sushi piece to the sushi tower */
        
        /* Copy original sushi piece */
        let newPiece = sushiBasePiece.copy() as! SushiPiece
        newPiece.connectChopsticks()
        
        /* Access last piece properties */
        let lastPiece = sushiTower.last
        
        /* Add on top of last piece, default on first piece */
        let lastPosition = lastPiece?.position ?? sushiBasePiece.position
        newPiece.position = lastPosition + CGPoint(x: 0, y: 55)
        
        /* Increment Z to ensure it's on top of the last piece, default on first piece*/
        let lastZPosition = lastPiece?.zPosition ?? sushiBasePiece.zPosition
        newPiece.zPosition = lastZPosition + 1
        
        /* Set side */
        newPiece.side = side
        
        /* Add sushi to scene */
        addChild(newPiece)
        
        /* Add sushi piece to the sushi tower */
        sushiTower.append(newPiece)
    }
    
    func addRandomPieces(_ total: Int) {
        /* Add random sushi pieces to the sushi tower */
        
        for _ in 1...total {
            
            /* Need to access last piece properties */
            let lastPiece = sushiTower.last as SushiPiece!
            
            /* Need to ensure we don't create impossible sushi structures */
            if lastPiece?.side != Side.none {
                addTowerPiece(Side.none)
            } else {
                
                /* Random Number Generator */
                let rand = CGFloat.random(min: 0, max: 1.0)
                
                if rand < 0.45 {
                    /* 45% Chance of a left piece */
                    addTowerPiece(.left)
                } else if rand < 0.9 {
                    /* 45% Chance of a right piece */
                    addTowerPiece(.right)
                } else {
                    /* 10% Chance of an empty piece */
                    addTowerPiece(.none)
                }
            }
        }
    }
    
    func gameOver() {
        /* Game over! */
        
        state = .gameOver
        
        /* Turn all the sushi pieces red*/
        for sushiPiece in sushiTower {
            sushiPiece.run(SKAction.colorize(with: UIColor.red, colorBlendFactor: 1.0, duration: 0.50))
        }
        
        /* Make the player turn red */
        character.run(SKAction.colorize(with: UIColor.red, colorBlendFactor: 1.0, duration: 0.50))
        
        /* Change play button selection handler */
        playButton.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene?.scaleMode = .aspectFill
            
            /* Restart GameScene */
            skView?.presentScene(scene)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        if state != .playing { return }
        
        /* Decrease Health */
        health -= 0.01
        
        /* Has the player ran out of health? */
        if health < 0 { gameOver() }
    }
    
}
