//
//  sushiPiece.swift
//  Sushi Neko
//
//  Created by Martin Walsh on 07/04/2016.
//  Copyright © 2016 Make School. All rights reserved.
//

import SpriteKit

class Character: SKSpriteNode {
    
    /* Character side */
    var side: Side = .Left {
        didSet {
            
            if side == .Left {
                xScale = 1
                position.x = 70
            } else {
                /* An easy way to flip an asset horizontally is to invert the X-axis scale */
                xScale = -1
                position.x = 252
            }
            
            /* Load/Run the punch action */
            let punch = SKAction(named: "Punch")!
            runAction(punch)
        }
    }
    
    
    
    // MARK: - Init
    
    init() {
        let texture = SKTexture(imageNamed: "character1")
        
        // Must implement the Designated Initializer
        super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
        
    }
    
    /* You are required to implement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
