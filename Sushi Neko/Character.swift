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
            
            /* Load our punch action */
            let punch = SKAction(named: "Punch")!
            
            if side == .Left {
                xScale = 1
                position.x = 70
            } else {
                /* An easy way to flip an asset horizontally is to invert the X-axis scale */
                xScale = -1
                position.x = 252
            }
            
            /* Run action */
            runAction(punch)
        }
    }
    
    /* You need to impplement this for your subclass to work */
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    /* You need to impplement this for your subclass to work */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
