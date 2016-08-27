//
//  sushiPiece.swift
//  Sushi Neko
//
//  Created by Martin Walsh on 07/04/2016.
//  Copyright © 2016 Make School. All rights reserved.
//

import SpriteKit

class Character: SKSpriteNode {
    
    let punch: SKAction
    
    /* Character side */
    var side: Side = .Left {
        didSet {
            
            if side == .Left {
                xScale = 1
                // position.x = 70
            } else {
                /* An easy way to flip an asset horizontally is to invert the X-axis scale */
                xScale = -1
                // position.x = 252
            }
            
            /* Load/Run the punch action */
            // let punch = SKAction(named: "Punch")!
            // run(punch)
            run(punch)
        }
    }
    
    
    
    // MARK: - Init

    init() {
        let texture = SKTexture(imageNamed: "character1")
        let punchTexture1 = SKTexture(imageNamed: "character2")
        let punchTexture2 = SKTexture(imageNamed: "character3")
        
        punch = SKAction.animate(with: [punchTexture1, punchTexture2, punchTexture1], timePerFrame: 0.05, resize: true, restore: true)
        
        // Must implement the Designated Initializer
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Setup 
    
    func setup() {
        anchorPoint.x = 1
    }
    
    
}
