//
//  GameScene.swift
//  Sushi Neko
//
//  Created by Martin Walsh on 05/04/2016.
//  Copyright (c) 2016 Make School. All rights reserved.
//

import SpriteKit
import Firebase
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKLoginKit

/* Tracking enum for use with character and sushi side */
enum Side {
    case Left, Right, None
}

/* Tracking enum for game state */
enum GameState {
    case Loading, Title, Ready, Playing, GameOver
}

/* Social profile structure */
struct Profile {
    var name = ""
    var imgURL = ""
    var facebookId = ""
    var score = 0
}

class GameScene: SKScene {
    
    /* Game objects */
    var character: Character!
    var sushiBasePiece: SushiPiece!
    var playButton: MSButtonNode!
    var healthBar: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var playerProfile = Profile()
    
    /* Sushi tower array */
    var sushiTower: [SushiPiece] = []
    
    /* Highscore custom dictionary */
    var scoreTower: [Int:Profile] = [:]
    
    /* Game management */
    var state: GameState = .Loading {
        didSet {
            if state == .Title {
                stackSushi()
            }
        }
    }
    
    /* Sushi piece creation counter */
    var sushiCounter = 0
    
    /* Firebase connection */
    let networkRef = Firebase(url:"https://radiant-heat-4408.firebaseio.com/highscore")
    
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
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        /* Connect game objects */
        character = childNodeWithName("character") as! Character
        sushiBasePiece = childNodeWithName("sushiBasePiece") as! SushiPiece
        
        /* UI game objects */
        playButton = childNodeWithName("playButton") as! MSButtonNode
        healthBar = childNodeWithName("healthBar") as! SKSpriteNode
        scoreLabel = childNodeWithName("scoreLabel") as! SKLabelNode
        
        /* Setup play button selection handler */
        playButton.selectedHandler = {
            
            /* Start game */
            self.state = .Ready
            
            /* Hide button */
            self.playButton.state = .MSButtonNodeStateHidden
        }
        
        /* Setup chopstick connections */
        sushiBasePiece.connectChopsticks()
        
        /* Facebook authentication check */
        if (FBSDKAccessToken.currentAccessToken() == nil) {
            
            /* No access token, begin FB authentication process */
            FBSDKLoginManager().logInWithReadPermissions(["public_profile","email","user_friends"], fromViewController:self.view?.window?.rootViewController, handler: {
                (facebookResult, facebookError) -> Void in
                
                if facebookError != nil {
                    print("Facebook login failed. Error \(facebookError)")
                } else if facebookResult.isCancelled {
                    print("Facebook login was cancelled.")
                } else {
                    let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                    
                    /* Perform firebase facebook authentication step */
                    self.networkRef.authWithOAuthProvider("facebook", token: accessToken,
                        withCompletionBlock: { error, authData in
                            
                            if error != nil {
                                print("Login failed. \(error)")
                            } else {
                                print("Logged in! \(authData)")
                            }
                    })
                }
            })
        }
        
        /* Facebook profile lookup */
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, first_name"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error == nil){
                    
                    /* Debug graph results */
                    //print(result)
                    
                    /* Update player profile */
                    self.playerProfile.facebookId = result.valueForKey("id") as! String
                    self.playerProfile.name = result.valueForKey("first_name") as! String
                    self.playerProfile.imgURL = "https://graph.facebook.com/\(self.playerProfile.facebookId)/picture?type=small"
                }
            })
        }
        
        /* Query firebase for highscores */
        networkRef.queryOrderedByChild("score").queryLimitedToLast(5).observeEventType(.Value, withBlock: { snapshot in
            
            /* Check snapshot has results */
            if snapshot.exists() {
                
                /* Loop through data entries */
                for child in snapshot.children {
                    
                    /* Debug snapshot child */
                    //print(child)
                    
                    /* Create new player profile */
                    var profile = Profile()
                    
                    /* Assign player name */
                    profile.name = child.key
                    
                    /* Assign player's profile image URL */
                    profile.imgURL = child.value.objectForKey("image") as! String
                    
                    /* Assign FacebookID */
                    profile.facebookId = child.value.objectForKey("id") as! String
                    
                    /* Assign Player Score */
                    let score = child.value.objectForKey("score") as! Int
                    profile.score = score
                    
                    /* Add new highscore profile to score tower using score as position in array */
                    self.scoreTower[score] = profile
                }
                
                /* Change game state */
                self.state = .Title
            } else {
                /* Change game state */
                self.state = .Title
            }
            
        })
        
    }
    
    func stackSushi() {
        /* Seed the sushi tower */
        
        /* Manually stack the start of the tower */
        addTowerPiece(.None)
        addTowerPiece(.Right)
        
        /* Randomize tower to just outside of the screen */
        addRandomPieces(10)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        /* Player ready? */
        if state == .Ready {
            state = .Playing
        }
        
        /* If not in playing state, return */
        if state != .Playing { return }
        
        for touch in touches {
            
            /* Get touch position in scene */
            let location = touch.locationInNode(self)
            
            /* Was touch on left/right hand side of screen? */
            if location.x > size.width / 2 {
                character.side = .Right
            } else {
                character.side = .Left
            }
            
            /* Grab sushi piece on top of the base sushi piece, it will always be 'first' */
            let firstPiece = sushiTower.first as SushiPiece!
            
            /* Check character side against sushi piece side (this is our death collision check)*/
            if character.side == firstPiece.side {
                
                /* Drop all the sushi pieces down a place (visually) */
                for node:SushiPiece in sushiTower {
                    node.runAction(SKAction.moveBy(CGVector(dx: 0, dy: -55), duration: 0.10))
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
            firstPiece.flip(character.side)
            
            /* Add a new sushi piece to the top of the sushi tower */
            addRandomPieces(1)
            
            /* Drop all the sushi pieces down one place */
            for node:SushiPiece in sushiTower {
                node.runAction(SKAction.moveBy(CGVector(dx: 0, dy: -55), duration: 0.10))
                
                /* Reduce zPosition to stop zPosition climbing over UI */
                node.zPosition--
            }
        }
    }
    
    func addTowerPiece(side: Side) {
        /* Add a new sushi piece to the sushi tower */
        
        /* Copy original sushi piece */
        let newPiece = sushiBasePiece.copy() as! SushiPiece
        newPiece.connectChopsticks()
        
        /* Access last piece properties */
        let lastPiece = sushiTower.last
        
        /* Add on top of last piece, default on first piece */
        let lastPosition = lastPiece?.position ?? sushiBasePiece.position
        newPiece.position = lastPosition + CGPoint(x: 0, y: 55)
        
        /* Incremenet Z to ensure it's on top of the last piece, default on first piece*/
        let lastZPosition = lastPiece?.zPosition ?? sushiBasePiece.zPosition
        newPiece.zPosition = lastZPosition + 1
        
        /* Set side */
        newPiece.side = side
        
        /* Add sushi to scene */
        addChild(newPiece)
        
        /* Add sushi piece to the sushi tower */
        sushiTower.append(newPiece)
        
        /* Sushi tracker */
        sushiCounter += 1
        
        /* Do we have a social score to add to the current sushi piece? */
        guard let profile = scoreTower[sushiCounter] else { return }
        
        /* Grab profile image */
        guard let imgURL = NSURL(string: profile.imgURL) else { return }
        
        /* Download profile image and create sprites asynchronously */
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            /* Perform image download task */
            guard let imgData = NSData(contentsOfURL: imgURL) else { return }
            guard let img = UIImage(data: imgData) else { return }
            
            /* Create new sprite nodes */
            dispatch_async(dispatch_get_main_queue(), {
                
                /* Create background border */
                let imgNodeBg = SKSpriteNode(color: UIColor.whiteColor(), size: CGSize(width: 52, height: 52))
                
                /* Create texture from image */
                let imgTex = SKTexture(image: img)
                
                /* Create a new sprite using profile texture, cap size */
                let imgNode = SKSpriteNode(texture: imgTex, size: CGSize(width: 50, height: 50))
                
                /* Add as child of sushi piece */
                newPiece.addChild(imgNodeBg)
                imgNodeBg.zPosition = newPiece.zPosition + 1
                
                /* Add social profile image as child of background */
                imgNodeBg.addChild(imgNode)
                imgNode.zPosition = imgNodeBg.zPosition + 1
                
            });
        }
        
    }
    
    func addRandomPieces(total: Int) {
        /* Add random sushi pieces to the sushi tower */
        
        for _ in 1...total {
            
            /* Need to access last piece properties */
            let lastPiece = sushiTower.last as SushiPiece!
            
            /* Need to ensure we don't create impossible sushi structures */
            if lastPiece.side != .None {
                addTowerPiece(.None)
            } else {
                
                /* Random Number Generator */
                let rand = CGFloat.random(min: 0, max: 1.0)
                
                if rand < 0.45 {
                    /* 45% Chance of a left piece */
                    addTowerPiece(.Left)
                } else if rand < 0.9 {
                    /* 45% Chance of a right piece */
                    addTowerPiece(.Right)
                } else {
                    /* 10% Chance of an empty piece */
                    addTowerPiece(.None)
                }
            }
        }
    }
    
    func gameOver() {
        /* Game over! */
        
        state = .GameOver
        
        /* Turn all the sushi pieces red*/
        for node:SushiPiece in sushiTower {
            node.runAction(SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 1.0, duration: 0.50))
        }
        
        /* Make the player turn red */
        character.runAction(SKAction.colorizeWithColor(UIColor.redColor(), colorBlendFactor: 1.0, duration: 0.50))
        
        /* Check for new highscore and is a valid FB user */
        if score > playerProfile.score && !playerProfile.facebookId.isEmpty {
            
            playerProfile.score = score
            
            /* Build data structure to be saved to firebase */
            let saveProfile = [playerProfile.name :
                ["image" : playerProfile.imgURL,
                    "score" : playerProfile.score,
                    "id" : playerProfile.facebookId ]]
            
            /* Save to firebase */
            networkRef.updateChildValues(saveProfile, withCompletionBlock: {
                (error:NSError?, ref:Firebase!) in
                if (error != nil) {
                    print("Data save failed: ",error)
                } else {
                    print("Data saved success")
                }
                
                /* Enable play button */
                self.playButton.state = .MSButtonNodeStateActive
            })
            
        }
        
        /* Change play button selection handler */
        playButton.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFill
            
            /* Restart GameScene */
            skView.presentScene(scene)
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if state != .Playing { return }
        
        /* Decrease Health */
        health -= 0.01
        
        /* Has the player ran out of health? */
        if health < 0 { gameOver() }
    }
    
}
