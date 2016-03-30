//
//  GameScene.swift
//  Flappy Bird
//
//  Created by Marco on 10/22/15.
//  Copyright (c) 2015 Marco. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var score = 0
    
    var pipeSpeed = 2.0
    
    var labelScore = SKLabelNode ()
    var labelGameOver = SKLabelNode ()
    
    // tudo que aparece na tela é um node
    var bird = SKSpriteNode ()
    var background = SKSpriteNode ()
    var pipe1 = SKSpriteNode ()
    var pipe2 = SKSpriteNode ()
    
    var movingObjects = SKSpriteNode ()
    
    var labelContainer = SKSpriteNode ()
    
    enum ColliderType: UInt32 {
        
        // os valores devem ser sempre o dobro do outro, 1, 2, 4, 8, 16, etc
        case Bird   = 1
        case Object = 2
        case Gap    = 4
    }
    
    var gameOver = false
    
    var backgroundMusicPlayer: AVAudioPlayer!
    
    func playBackgroundMusic(filename: String) {
        
        do {
            try backgroundMusicPlayer = AVAudioPlayer(contentsOfURL: NSURL (fileURLWithPath: NSBundle.mainBundle().pathForResource("backgroundMusic", ofType: "mp3")!), fileTypeHint:nil)
            
            backgroundMusicPlayer.numberOfLoops = -1
            backgroundMusicPlayer.prepareToPlay()
            backgroundMusicPlayer.volume = 0.2
            backgroundMusicPlayer.play()

        } catch {
            //Handle the error
            print ("Could not create audio player")
            return
        }
    }
    
    
    func makeBackground () {
        // ******** background ********
        
        let backgroundTexture = SKTexture (imageNamed: "bg")
        
        // negativo no x significa mover para a esquerda
        let moveBackground = SKAction.moveByX (-backgroundTexture.size().width, y: 0, duration: 9)
        
        // quando o fundo terminar, ele repete a imagem
        let replaceBackground = SKAction.moveByX (backgroundTexture.size().width, y: 0, duration: 0)
        
        // faz as 2 em sequencia, 1a uma que dura 9 segundos e depois a outra e depois repete
        let moveBackgroundForever = SKAction.repeatActionForever (SKAction.sequence ([moveBackground, replaceBackground]))
        
        for var i : CGFloat = 0; i < 3; i++ {
            background = SKSpriteNode (texture: backgroundTexture)
            
            background.position = CGPoint (x: backgroundTexture.size().width / 2 + backgroundTexture.size().width * i, y: CGRectGetMidY (self.frame))
            
            // quanto menor o valor, mais atrás ele fica. logo, os personagens ficam positivos e o fundo como
            // zero ou negativo
            background.zPosition = -1
            
            // faz a imagem esticar até o tamanho da tela
            background.size.height = self.frame.height
            
            background.runAction (moveBackgroundForever)
            
            movingObjects.addChild (background)
        }
    }
    
    // equivalente ao viewDidLoad, é a 1a coisa a ser chamada
    override func didMoveToView(view: SKView) {

        playBackgroundMusic ("backgroundMusic,mp3")
        
        runAction (SKAction.playSoundFileNamed ("welcome.wav", waitForCompletion: false))
        
        // pra implementar o delegate
        self.physicsWorld.contactDelegate = self
        
        self.addChild (movingObjects)
        self.addChild (labelContainer)
        
        makeBackground ()
        
        labelScore.fontName = "Helvetica"
        labelScore.fontSize = 60
        labelScore.text = "0"
        labelScore.position = CGPointMake (CGRectGetMidX (self.frame), self.frame.size.height - 70)
        labelScore.zPosition = 5
        
        self.addChild (labelScore)
        
        
        // ******** bird ********
        
        let birdTexture1 = SKTexture (imageNamed: "flappy1")
        let birdTexture2 = SKTexture (imageNamed: "flappy2")
        
        // cria uma animação com as imagens
        let animation = SKAction.animateWithTextures ([birdTexture1, birdTexture2], timePerFrame: 0.1)
        
        // diz que a action se repete para sempre
        let makeBirdFlap = SKAction.repeatActionForever (animation)
        
        bird = SKSpriteNode (texture: birdTexture1)

        // pega as coordenadas do meio da tela
        bird.position = CGPoint (x: CGRectGetMidX (self.frame), y: CGRectGetMidY (self.frame) + 400)
        
        bird.zPosition = 10
        
        // adiciona a action à variável
        bird.runAction (makeBirdFlap)
        
        // aplica física ao pássaro. Seu raio é a metade do seu tamanho
        bird.physicsBody = SKPhysicsBody (circleOfRadius: birdTexture1.size ().height / 2)
        
        // aplicar gravidade
        bird.physicsBody!.dynamic = true

        // ******** collisions ********
        
        bird.physicsBody!.categoryBitMask = ColliderType.Bird.rawValue
        
        // para poder detectar colisão entre todos os tipos do enum
        bird.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        
        // decide se um objeto pode passar por outro tipo ou não
        // se bird tem o mesmo valor de objeto, então não podem ser atravessados
        bird.physicsBody!.collisionBitMask = ColliderType.Object.rawValue
        
        // adiciona o node à cena
        self.addChild (bird)

        
        // ******** ground ********

        // cria o chão. Não é um sprite pois não tem uma imagem associada, o usuário não pode ver!
        let ground = SKNode ()
        
        ground.position = CGPointMake (0,0)
        
        // fica do tamanho da tela (width)
        ground.physicsBody = SKPhysicsBody (rectangleOfSize: CGSizeMake(self.frame.size.width, 1))
        
        // o chão não é afetado pela gravidade para permanecer no local
        ground.physicsBody!.dynamic = false

        ground.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        
        // é o mesmo que foi setado no Bird, por isso podemos detectar colisão entre ambos
        ground.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        
        ground.physicsBody!.collisionBitMask = ColliderType.Object.rawValue

        
        self.addChild (ground)
        
        // ******** pipes ********

        _ = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: Selector ("makePipes"), userInfo: nil, repeats: true)
    }
    
    func makePipes () {
        // tamanho do gap entre os canos
        let gapHeight = bird.size.height * 4
        
        let movementAmount = arc4random () % UInt32 (self.frame.size.height / 2)
        
        let pipeOffset = CGFloat (movementAmount) - self.frame.size.height / 4
        
        // usou a width para que a velocidade seja sempre a mesma mesmo com widths diferentes
        let movePipes = SKAction.moveByX (-self.frame.size.width * 2 /* * CGFloat (self.pipeSpeed)*/, y: 0, duration: NSTimeInterval (self.frame.width / 100))
        let removePipes = SKAction.removeFromParent()
        
        let moveAndRemovePipes = SKAction.sequence([movePipes, removePipes])
        
        let pipeTexture1 = SKTexture (imageNamed: "pipe1")
        let pipe1 = SKSpriteNode (texture: pipeTexture1)
        
        pipe1.position = CGPoint (x: CGRectGetMidX(self.frame) + self.frame.size.width, y: CGRectGetMidY (self.frame) + pipeTexture1.size().height / 2 + gapHeight / 2 + pipeOffset)
        
        pipe1.runAction(moveAndRemovePipes)
        
        pipe1.physicsBody = SKPhysicsBody (rectangleOfSize: pipeTexture1.size())
        
        pipe1.physicsBody!.dynamic = false
        
        pipe1.physicsBody!.categoryBitMask    = ColliderType.Object.rawValue
        pipe1.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        pipe1.physicsBody!.collisionBitMask   = ColliderType.Object.rawValue

        
        movingObjects.addChild (pipe1)
        
        
        let pipeTexture2 = SKTexture (imageNamed: "pipe2")
        let pipe2 = SKSpriteNode (texture: pipeTexture2)
        
        pipe2.position = CGPoint (x: CGRectGetMidX(self.frame) + self.frame.size.width, y: CGRectGetMidY (self.frame) - pipeTexture2.size().height / 2 - gapHeight / 2 + pipeOffset)
        
        pipe2.runAction(moveAndRemovePipes)

        pipe2.physicsBody = SKPhysicsBody (rectangleOfSize: pipeTexture1.size())

        pipe2.physicsBody!.dynamic = false
        
        pipe2.physicsBody!.categoryBitMask    = ColliderType.Object.rawValue
        pipe2.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        pipe2.physicsBody!.collisionBitMask   = ColliderType.Object.rawValue

        
        movingObjects.addChild (pipe2)
    
        
        let gap = SKNode ()
        
        gap.position = CGPoint (x: CGRectGetMidX(self.frame) + self.frame.size.width + 30, y: CGRectGetMidY (self.frame) + pipeOffset)
    
        // para o gap se auto-destruir após o fim da tela, assim como os pipes
        gap.runAction (moveAndRemovePipes)
        
        gap.physicsBody = SKPhysicsBody (rectangleOfSize: CGSizeMake (pipe1.size.width, gapHeight))
        
        gap.physicsBody!.dynamic = false
        
        // a categoria do objeto
        gap.physicsBody!.categoryBitMask    = ColliderType.Gap.rawValue
        
        // colisão com o pássaro
        gap.physicsBody!.contactTestBitMask = ColliderType.Bird.rawValue
        
        // pode atravessar
        gap.physicsBody!.collisionBitMask   = ColliderType.Gap.rawValue

        movingObjects.addChild (gap)
    }
    
    // função chamada quando ocorre uma colisão
    func didBeginContact(contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask == ColliderType.Gap.rawValue || contact.bodyB.categoryBitMask == ColliderType.Gap.rawValue {
            score++
            
            labelScore.text = String (score)
            
            runAction (SKAction.playSoundFileNamed ("score.wav", waitForCompletion: false))
            
            if score > 0 && score % 6 == 0 {
                
                if self.pipeSpeed <= 10.0 {
                    self.pipeSpeed += 2.0
                }
                
                runAction (SKAction.playSoundFileNamed ("hurry.wav", waitForCompletion: false))
            }
            else if score > 0 && score % 3 == 0 {
                    runAction (SKAction.playSoundFileNamed ("welldone.wav", waitForCompletion: false))
            }
            
        } else {
            
            // pois pode ocorrer de ele chamar a função mais de uma vez e dá erro ao colocar a label 2x
            if gameOver == false {
            
                gameOver = true
                
                self.speed = 0
                self.pipeSpeed = 2.0
                
                labelGameOver.fontName = "Helvetica"
                labelGameOver.fontSize = 30
                labelGameOver.text     = "Game Over! Tap to play again."
                
                labelGameOver.position = CGPointMake (CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
                
                labelContainer.addChild (labelGameOver)
                
                runAction (SKAction.playSoundFileNamed ("gameover.wav", waitForCompletion: false))
            }
        }
    }

    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        runAction (SKAction.playSoundFileNamed ("button_press.wav", waitForCompletion: false))
        
        if gameOver == false {
            // cria um impulso (como uma força no objeto)
            bird.physicsBody!.velocity = CGVectorMake (0, 0)
            
            // o tanto que ele anda, 0 na horizontal e 50 na vertical
            bird.physicsBody!.applyImpulse(CGVectorMake(0, 50))
        } else {
            score = 0
            labelScore.text = "0"
            
            bird.position = CGPointMake (CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) + 400)
            
            bird.physicsBody!.velocity = CGVectorMake (0, 0)
            
            movingObjects.removeAllChildren()
            
            makeBackground ()
            
            self.speed = 1
            
            gameOver = false
            
            labelContainer.removeAllChildren ()

            runAction (SKAction.playSoundFileNamed ("extra_life.m4a", waitForCompletion: false))
        }
        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
