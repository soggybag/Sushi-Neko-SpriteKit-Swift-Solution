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
    case Left, Right, None
}

/* Tracking enum for game state */
enum GameState {
    case Title, Ready, Playing, GameOver
}




class GameScene: SKScene {
    
    /* Some useful numbers */
    let sushiPieceHeight: CGFloat = 55
    let firstPieceY: CGFloat = 200
    
    /* Game objects */
    let character: Character
    let sushiBasePiece: SushiPiece
    let playButton: MSButtonNode
    let healthBar: SKSpriteNode
    let scoreLabel: SKLabelNode
    
    /* Sushi tower array */
    var sushiTower: [SushiPiece] = []
    
    /* Game management */
    var state: GameState = .Title
    
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
    
    
    
    // MARK: - Init
    
    override init(size: CGSize) {
        character = Character()
        sushiBasePiece = SushiPiece()
        playButton = MSButtonNode(imageNamed: "button")
        healthBar = SKSpriteNode(imageNamed: "life")
        scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        
        super.init(size: size)
        
        /* Setup all of the elements */
        setupBackground()
        setupCharacter()
        setupSushi()
        setupPlayButton()
        setupHealthBar()
        setupScoreLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    // MARK: - Setup
    
    func setupBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        addChild(background)
        background.anchorPoint = CGPoint(x: 0, y: 0)
        // TODO: resize with proportion for screen size...
        background.size = size
    }
    
    func setupCharacter() {
        addChild(character)
        character.position.x = size.width / 2
        character.position.y = firstPieceY
        character.zPosition = 99
    }
    
    func setupSushi() {
        addChild(sushiBasePiece)
        sushiBasePiece.position.x = size.width / 2
        sushiBasePiece.position.y = firstPieceY
    }
    
    func setupPlayButton() {
        addChild(playButton)
        playButton.position.x = size.width / 2
        playButton.position.y = 75
        
        /* Setup play button selection handler */
        playButton.selectedHandler = {
            /* Start game */
            self.state = .Ready
        }
    }
    
    func setupHealthBar() {
        let healthBack = SKSpriteNode(imageNamed: "life_bg")
        addChild(healthBack)
        healthBack.position.x = size.width / 2
        healthBack.position.y = size.height - 50
        healthBack.zPosition = 88
        
        addChild(healthBar)
        healthBar.anchorPoint.x = 0
        healthBar.position.x = size.width / 2 - healthBar.size.width / 2
        healthBar.position.y = healthBack.position.y
        healthBar.zPosition = 99
    }
    
    func setupScoreLabel() {
        addChild(scoreLabel)
        scoreLabel.fontSize = 56
        scoreLabel.position.x = size.width / 2
        scoreLabel.position.y = size.height * 0.66
        scoreLabel.text = "0"
    }
    
    
    
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        state = .Ready
        
        /* Manually stack the start of the tower */
        addTowerPiece(side: .None)
        addTowerPiece(side: .Right)
        
        /* Randomize tower to just outside of the screen */
        addRandomPieces(total: 10)
    }
    
    
    
    
    // MARK: - Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        
        /* Game not ready to play */
        if state == .GameOver || state == .Title { return }
        
        /* Game begins on first touch */
        if state == .Ready {
            state = .Playing
        }
        
        let touch = touches.first!
        /* Get touch position in scene */
        let location = touch.location(in: self)
        
        /* Was touch on left/right hand side of screen? */
        if location.x > size.width / 2 {
            character.side = .Right
        } else {
            character.side = .Left
        }
        
        /* Grab sushi piece on top of the base sushi piece, it will always be 'first' */
        let firstPiece = sushiTower.first as SushiPiece!
        
        /* Check character side against sushi piece side (this is our death collision check)*/
        if character.side == firstPiece?.side {
            
            // dropTower()
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
        addRandomPieces(total: 1)
        
        /* Drop all the sushi pieces down one place */
        /*for node:SushiPiece in sushiTower {
            // node.run(SKAction.move(by: CGVector(dx: 0, dy: -sushiPieceHeight), duration: 0.10))
            // dropTower()
            
            /* Reduce zPosition to stop zPosition climbing over UI */
            node.zPosition -= 1
        }*/
    
    }
    
    
    
    
    
    // MARK: - Utility Functions
    
    func addTowerPiece(side: Side) {
        /* Add a new sushi piece to the sushi tower */
        
        /* Copy original sushi piece */
        let newPiece = sushiBasePiece.copy() as! SushiPiece
        
        /* Access last piece properties */
        let lastPiece = sushiTower.last
        
        /* Add on top of last piece, default on first piece */
        let lastPosition = lastPiece?.position ?? sushiBasePiece.position
        newPiece.position = lastPosition + CGPoint(x: 0, y: sushiPieceHeight)
        
        /* Increment Z to ensure it's on top of the last piece, default on first piece */
        let lastZPosition = lastPiece?.zPosition ?? sushiBasePiece.zPosition
        newPiece.zPosition = lastZPosition + 1
        
        /* Set side */
        newPiece.side = side
        
        /* Add sushi to scene */
        addChild(newPiece)
        
        /* Add sushi piece to the sushi tower */
        sushiTower.append(newPiece)
    }
    
    func addRandomPieces(total: Int) {
        /* Add random sushi pieces to the sushi tower */
        
        print("addRandomPiece total:\(total)")
        
        for _ in 1...total {
            /* Need to access last piece properties */
            let lastPiece = sushiTower.last
            
            print("Last Piece side: \(lastPiece?.side)")
            
    
                
            /* Random Number Generator */
            let rand = CGFloat.random(min: 0, max: 1.0)
            
            print(lastPiece?.side != Side.None)
            
            if lastPiece?.side != Side.None {
                addTowerPiece(side: Side.None)
                
            } else if rand < 0.45 {
                /* 45% Chance of a left piece */
                addTowerPiece(side: .Left)
                
            } else if rand < 0.9 {
                /* 45% Chance of a right piece */
                addTowerPiece(side: .Right)
                
            } else {
                /* 10% Chance of an empty piece */
                addTowerPiece(side: .None)
                
            }
            
        }
    }
    
    func gameOver() {
        /* Game over! */
        
        state = .GameOver
        
        /* Turn all the sushi pieces red*/
        for node:SushiPiece in sushiTower {
            node.run(SKAction.colorize(with: UIColor.red, colorBlendFactor: 1.0, duration: 0.50))
        }
        
        // Make the player turn red
        character.run(SKAction.colorize(with: UIColor.red, colorBlendFactor: 1.0, duration: 0.50))
        
        // Change play button selection handler
        playButton.selectedHandler = {
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(size: self.view!.frame.size) as GameScene!
            
            /* Ensure correct aspect mode */
            scene?.scaleMode = .aspectFill
            
            /* Restart GameScene */
            skView?.presentScene(scene)
        }
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        
        moveTowerDown()
        
        /* Called before each frame is rendered */
        if state != .Playing { return }
        
        /* Decrease Health */
        health -= 0.01
        
        /* Has the player ran out of health? */
        if health < 0 { gameOver() }
    }
    
    func moveTowerDown() {
        var n: CGFloat = 0
        for piece in sushiTower {
            let y = (n * sushiPieceHeight) + firstPieceY + sushiPieceHeight
            piece.position.y -= (piece.position.y - y) * 0.5
            n += 1
        }
    }
    
    func dropTower() {
        /* Drop all the sushi pieces down a place (visually) */
        for node:SushiPiece in sushiTower {
            node.run(SKAction.move(by: CGVector(dx: 0, dy: -sushiPieceHeight), duration: 0.10))
        }
    }
    
}
