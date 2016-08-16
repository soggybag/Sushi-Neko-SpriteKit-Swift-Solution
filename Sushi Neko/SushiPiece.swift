//
//  sushiPiece.swift
//  Sushi Neko
//
//  Created by Martin Walsh on 07/04/2016.
//  Copyright © 2016 Make School. All rights reserved.
//

import SpriteKit

class SushiPiece: SKSpriteNode {
    
    /* Chopstick objects */
    let rightChopstick: SKSpriteNode
    let leftChopstick: SKSpriteNode
    
    /* Sushi type */
    var side: Side = .None {
        
        didSet {
            switch side {
            case .Left:
                /* Show left chopstick */
                leftChopstick.hidden = false
            case .Right:
                /* Show right chopstick */
                rightChopstick.hidden = false
            case .None:
                /* Hide all chopsticks */
                leftChopstick.hidden = true
                rightChopstick.hidden = true
            }
            
        }
    }
    
    
    
    
    // MARK: - Init
    
    init() {
        rightChopstick = SKSpriteNode(imageNamed: "chopstick")
        leftChopstick = SKSpriteNode(imageNamed: "chopstick")
        
        let texture = SKTexture(imageNamed: "roll")
        
        super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: - Setup
    
    func setup() {
        addChild(rightChopstick)
        addChild(leftChopstick)
        
        print(leftChopstick.position.x)
        print(leftChopstick.hidden)
        
        rightChopstick.xScale = -1
        rightChopstick.anchorPoint.x = 1.4
        leftChopstick.anchorPoint.x = 1.4
        
        rightChopstick.position.y = 35
        leftChopstick.position.y = 35
        
        /* Set the default side */
        side = .None
    }
    
    
    
    // MARK: - Utility
    
    func flip(side: Side) {
        /* Flip the sushi out of the screen */
        
        var actionName: String = ""
        
        if side == .Left {
            actionName = "FlipRight"
        } else if side == .Right {
            actionName = "FlipLeft"
        }
        
        /* Load appropriate action */
        let flip = SKAction(named: actionName)!
        
        /* Create a node removal action */
        let remove = SKAction.removeFromParent()
        
        /* Build sequence, flip then remove from scene */
        let sequence = SKAction.sequence([flip,remove])
        runAction(sequence)
    }
    
}
