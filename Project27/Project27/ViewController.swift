//
//  ViewController.swift
//  Project27
//
//  Created by Timothy on 03/06/2023.
// The most important thing to understand is that, like Core Animation, Core Graphics sits at a lower technical level than UIKit. This means it doesn't understand classes you know like UIColor and UIBezierPath, so you either need to use their counterparts (CGColor and CGPath respectively), or use helper methods from UIKit that convert between the two.
// Second, you need to understand that Core Graphics differentiates between creating a path and drawing a path. That is, you can add lines, squares and other shapes to a path as much as you want to, but none of it will do anything until you actually draw the path. Think of it like a simple state machine: you configure a set of states you want (colors, transforms, and so on), then perform actions. You can even maintain multiple states at a time by pushing and popping in order to backup and restore specific states.
// Finally, you should know that Core Graphics is extremely fast: you can use it for updating drawing in real time, and you'll be very impressed. Core Graphics can work on a background thread – something that UIKit can't do – which means you can do complicated drawing without locking up your user interface.



import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    var currentDrawType = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        drawRectangle()
    }


    @IBAction func redrawTapped(_ sender: Any) {
        currentDrawType += 1
        
        if currentDrawType > 5 {
            currentDrawType = 0
        }
        
        switch currentDrawType {
        case 0:
            drawRectangle()
            
        case 1:
            drawCircle()
            
        case 2:
            drawCheckerboard()
            
        case 3:
            drawRotatedSquares()

        case 4:
            drawLines()
            
        case 5:
            drawImagesAndText()
            
        default:
            break
        }
    }
    
    func drawRectangle() {
        // It’s time to meet the UIGraphicsImageRenderer class. This was introduced in iOS 10 to allow fast and easy graphics rendering, while also quietly adding support for wide color devices like the iPad Pro. It works with closures, which might seem annoying if you’re still not comfortable with them, but has the advantage that you can build complex drawing instructions by composing functions.
        // Now, wait a minute: that class name starts with "UI", so what makes it anything to do with Core Graphics? Well, it isn’t a Core Graphics class; it’s a UIKit class, but it acts as a gateway to and from Core Graphics for UIKit-based apps like ours. You create a renderer object and start a rendering context, but everything between will be Core Graphics functions or UIKit methods that are designed to work with Core Graphics contexts.
        // In Core Graphics, a context is a canvas upon which we can draw, but it also stores information about how we want to draw (e.g., what should our line thickness be?) and information about the device we are drawing to. So, it's a combination of canvas and metadata all in one, and it's what you'll be using for all your drawing. This Core Graphics context is exposed to us when we render with UIGraphicsImageRenderer.
        // When you create a renderer, you get to specify how big it should be, whether it should be opaque or not, and what pixel to point scale you want. To kick off rendering you can either call the image() function to get back a UIImage of the results, or call the pngData() and jpegData() methods to get back a Data object in PNG or JPEG format respectively.
        // In that code, we create a UIGraphicsImageRenderer with the size 512x512, leaving it with default values for scale and opacity – that means it will be the same scale as the device (e.g. 2x for retina) and transparent.
        // Creating the renderer doesn’t actually start any rendering – that’s done in the image() method. This accepts a closure as its only parameter, which is code that should do all the drawing. It gets passed a single parameter that I’ve named ctx, which is a reference to a UIGraphicsImageRendererContext to draw to. This is a thin wrapper around another data type called CGContext, which is where the majority of drawing code lives.
        // When the rendering has finished it gets placed into the image constant, which in turn gets sent to the image view for display. Our rendering code is empty right now, but it will still result in an empty 512x512 image being created.
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        
        let img = renderer.image { ctx in
            // awesome drawing code!!!
            let rectangle = CGRect(x: 0, y: 0, width: 512, height: 512)
            
            ctx.cgContext.setFillColor(UIColor.red.cgColor)
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(10)
            
            ctx.cgContext.addRect(rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
        }
        
        imageView.image = img
    }
    
    func drawCircle() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        
        let img = renderer.image { ctx in
            // awesome drawing code!!!
            let rectangle = CGRect(x: 0, y: 0, width: 512, height: 512).insetBy(dx: 5, dy: 5)
            
            ctx.cgContext.setFillColor(UIColor.red.cgColor)
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(10)
            
            ctx.cgContext.addEllipse(in: rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
        }
        
        imageView.image = img
    }
    // The only piece of code in there that you won't recognize is fill(), which skips the add path / draw path work and just fills the rectangle given as its parameter using whatever the current fill color is. You already know about ranges and modulo, so you should be able to see that this method makes every other square black, alternating between rows.
    // There are two things to be aware of with that code. First, we're filling every other square in black, but leaving the other squares alone. As we haven’t specified that our renderer is opaque, this means those places where we haven't filled anything will be transparent. So, if the view behind was green, you'd get a black and green checkerboard. Second, you can actually make checkerboards using a Core Image filter – check out CICheckerboardGenerator to see how!
    func drawCheckerboard() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        
        let img = renderer.image { ctx in
                ctx.cgContext.setFillColor(UIColor.black.cgColor)

                for row in 0 ..< 8 {
                    for col in 0 ..< 8 {
                        if (row + col) % 2 == 0 {
                            ctx.cgContext.fill(CGRect(x: col * 64, y: row * 64, width: 64, height: 64))
                        }
                    }
                }
            }

        imageView.image = img
    }
    // The current transformation matrix is very similar to those CGAffineTransform modifications we used in project 15, except its application is a little different in Core Graphics. In UIKit, you rotate drawing around the center of your view, as if a pin was stuck right through the middle. In Core Graphics, you rotate around the top-left corner, so to avoid that we're going to move the transformation matrix half way into our image first so that we've effectively moved the rotation point.
    // This also means we need to draw our rotated squares so they are centered on our center: for example, setting their top and left coordinates to be -128 and their width and height to be 256.
    // Modifying the CTM is cumulative, which is what makes this code work. That is, when you rotate the CTM, that transformation is applied on top of what was there already, rather than to a clean slate. So the code works by rotating the CTM a small amount more every time the loop goes around.
    func drawRotatedSquares() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        
        let img = renderer.image { ctx in
            // translateBy() translates (moves) the current transformation matrix.
            ctx.cgContext.translateBy(x: 256, y: 256)
            
            let rotations = 16
            let amount = Double.pi / Double(rotations)
            
            for _ in 0 ..< rotations {
                // rotate(by:) rotates the current transformation matrix.
                ctx.cgContext.rotate(by: CGFloat(amount))
                ctx.cgContext.addRect(CGRect(x: -128, y: -128, width: 256, height: 256))
            }
            
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            // strokePath() strokes the path with your specified line width, which is 1 if you don't set it explicitly.
            ctx.cgContext.strokePath()
        }
        
        imageView.image = img
    }
    
    // I'm going to make this translate and rotate the CTM again, although this time the rotation will always be 90 degrees. This method is going to draw boxes inside boxes, always getting smaller, like a square spiral. It's going to do this by adding a line to more or less the same point inside a loop, but each time the loop rotates the CTM so the actual point the line ends has moved too. It will also slowly decrease the line length, causing the space between boxes to shrink like a spiral.
    func drawLines() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        
        let img = renderer.image { ctx in
            ctx.cgContext.translateBy(x: 256, y: 256)
            
            var first = true
            var length: CGFloat = 256
            
            for _ in 0 ..< 256 {
                ctx.cgContext.rotate(by: .pi / 2)
                
                if first {
                    ctx.cgContext.move(to: CGPoint(x: length, y: 50))
                    first = false
                } else {
                   ctx.cgContext.addLine(to: CGPoint(x: length, y: 50))
                }
                
                length *= 0.99
            }
            
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            // strokePath() strokes the path with your specified line width, which is 1 if you don't set it explicitly.
            ctx.cgContext.strokePath()
        }
        
        imageView.image = img
    }
    
    // If you have an attributed string in Swift, how can you place it into a graphic? The answer is simpler than you think: attributed strings have a built-in method called draw(with:) that draws the string in a rectangle you specify. Even better, your attributed string styles are used to customize the font and size, the formatting, the line wrapping and more all with that one method.
    // Remarkably, the same is true of UIImage: any image can be drawn straight to a context, and it will even take into account the coordinate reversal of Core Graphics.
    func drawImagesAndText() {
        // 1. Create a renderer at the correct size.
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 512, height: 512))
        
        let img = renderer.image { ctx in
            // 2. Define a paragraph style that aligns text to the center.
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            // 3. Create an attributes dictionary containing that paragraph style, and also a font.
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36),
                .paragraphStyle: paragraphStyle
            ]
            
            // 4. Wrap that attributes dictionary and a string into an instance of NSAttributedString.
            let string = "The best-laid schemes o'\nmice an' men gang aft agley"
            let attributedString = NSAttributedString(string: string, attributes: attrs)
            
            // 5. Load an image from the project and draw it to the context.
            attributedString.draw(with: CGRect(x: 32, y: 32, width: 448, height: 448), options: .usesLineFragmentOrigin, context: nil)
            let mouse = UIImage(named: "mouse")
            mouse?.draw(at: CGPoint(x: 300, y: 150))
        }
        
        // 6. Update the image view with the finished result.
        imageView.image = img
    }
}

