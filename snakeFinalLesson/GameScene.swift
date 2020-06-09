//
//  GameScene.swift
//  snakeFinalLesson
//
//  Created by Alexander Myskin on 08.06.2020.
//  Copyright © 2020 Alexander Myskin. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var gameFrameRect: CGRect = .zero
    var gameFrameView: SKShapeNode!
    var startButton: SKLabelNode!
    var stopButton: SKLabelNode!
    var snake: Snake? 
    
    override func didMove(to view: SKView) {
        
        setup(in: view)

    }
    
    
    private func setup(in view: SKView) {
        backgroundColor = SKColor.black

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.allowsRotation = false
        physicsBody?.categoryBitMask = CollisionCategories.EdgeBody
        physicsBody?.collisionBitMask = CollisionCategories.Snake | CollisionCategories.SnakeHead
        view.showsPhysics = true



        guard let scene = view.scene else {
            return
        }

        let counterClockwiseButton = ControlsFactory.makeButton(at: CGPoint(x: scene.frame.minX + 30, y: scene.frame.minY + 50),
                                                                name: .counterClockwiseButtonName)
        addChild(counterClockwiseButton)

        let clockwiseButton = ControlsFactory.makeButton(at: CGPoint(x: scene.frame.maxX - 80, y: scene.frame.minY + 50),
                                                         name: .clockwiseButtonName)
        addChild(clockwiseButton)

        startButton = SKLabelNode(text: "START")
        startButton.position = CGPoint(x: scene.frame.midX, y: 55)
        startButton.fontSize = 40
        startButton.fontColor = .green
        startButton.name = .startButtonName
        addChild(startButton)

        stopButton = SKLabelNode(text: "STOP")
        stopButton.position = CGPoint(x: scene.frame.midX, y: 55)
        stopButton.fontSize = 40
        stopButton.fontColor = .red
        stopButton.name = .stopButtonName
        stopButton.isHidden = true
        addChild(stopButton)
    }
    

    // Создаем яблоко в случайной точке сцены
        func createApple(){
    // Случайная точка на экране
            let randX  = CGFloat(arc4random_uniform(UInt32(view!.scene!.frame.maxX-5)) + 1)
            let randY  = CGFloat(arc4random_uniform(UInt32(view!.scene!.frame.maxY-5)) + 1)
    // Создаем яблоко
            let apple = Apple(position: CGPoint(x: randX, y: randY))
    // Добавляем яблоко на сцену
            gameFrameView.addChild(apple)
        }

    
    // вызывается при нажатии на экран
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchedNode = findTouchedNode(with: touches) else {
            return
        }
        
        if let shapeNode = touchedNode as? SKShapeNode,
            touchedNode.name == .counterClockwiseButtonName || touchedNode.name == .clockwiseButtonName {
            shapeNode.fillColor = .green
            if touchedNode.name == .counterClockwiseButtonName {
                snake?.moveCounterClockwise()
            } else if touchedNode.name == .clockwiseButtonName {
                snake?.moveClockwise()
            }
        } else if touchedNode.name == .startButtonName {
            print("start")
            start()
        } else if touchedNode.name == .stopButtonName {
            print("stop")
            stop()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchedNode = findTouchedNode(with: touches) else {
            return
        }
        
        if let shapeNode = touchedNode as? SKShapeNode,
            touchedNode.name == "counterClockwiseButton" || touchedNode.name == "clockwiseButton" {
            shapeNode.fillColor = .gray
        }
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchedNode = findTouchedNode(with: touches) else {
            return
        }

        if let shapeNode = touchedNode as? SKShapeNode,
            touchedNode.name == "counterClockwiseButton" || touchedNode.name == "clockwiseButton" {
            shapeNode.fillColor = .gray
        }
    }
    
    private func findTouchedNode(with touches: Set<UITouch>) -> SKNode? {
        return touches.map { [unowned self] touch in touch.location(in: self) }
            .map { atPoint($0) }
            .first
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        snake?.move()
        
    }
    private func start() {
        guard let scene = scene else { return }

        snake = Snake(atPoint: CGPoint(x: scene.frame.midX, y: scene.frame.midY))
        gameFrameView = SKShapeNode(rect: gameFrameRect)
        addChild(gameFrameView)
        gameFrameView.addChild(snake!)
        
        //self.addChild(snake!)

               createApple()

               startButton.isHidden = true
               stopButton.isHidden = false
    }
    
    
    private func stop() {
        snake = nil
        
       //self.removeAllChildren()
        gameFrameView.removeAllChildren()
        //snake = nil
      
        startButton.isHidden = false
              stopButton.isHidden = true
    }
}


// Категория пересечения объектов
struct CollisionCategories{
// Тело змеи
    static let Snake: UInt32 = 0x1 << 0
// Голова змеи
    static let SnakeHead: UInt32 = 0x1 << 1
// Яблоко
    static let Apple: UInt32 = 0x1 << 2
// Край сцены (экрана)
    static let EdgeBody:   UInt32 = 0x1 << 3
}

// Имплементируем протокол
extension GameScene: SKPhysicsContactDelegate {
// Добавляем метод отслеживания начала столкновения
    func didBegin(_ contact: SKPhysicsContact) {
    // логическая сумма масок соприкоснувшихся объектов
            let bodyes = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    // вычитаем из суммы голову змеи, и у нас остается маска второго объекта
            let collisionObject = bodyes ^ CollisionCategories.SnakeHead
    // проверяем, что это за второй объект
            switch collisionObject {
            case CollisionCategories.Apple: // проверяем, что это яблоко
    // яблоко – это один из двух объектов, которые соприкоснулись. Используем тернарный оператор, чтобы вычислить, какой именно
                let apple = contact.bodyA.node is Apple ? contact.bodyA.node : contact.bodyB.node
    // добавляем к змее еще одну секцию
                snake?.addBodyPart()
    // удаляем съеденное яблоко со сцены
                apple?.removeFromParent()
    // создаем новое яблоко
                createApple()
            case CollisionCategories.EdgeBody: // проверяем, что это стенка экрана
                print("край экрана")
                stop()
                break                         // соприкосновение со стеной будет домашним заданием
            default:
                break
            }
        }
}
private extension String {
    static let counterClockwiseButtonName = "counterClockwiseButton"
    static let clockwiseButtonName = "clockwiseButton"

    static let startButtonName = "startButton"
    static let stopButtonName = "stopButton"
}
