// Playground - noun: a place where people can play

import UIKit
// import XCPlayground

class FirstButton: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        println("button loaded")
        
        let button   = UIButton.buttonWithType(UIButtonType.System) as UIButton
        button.frame = CGRectMake(100, 100, 100, 50)
        button.backgroundColor = UIColor.greenColor()
        button.setTitle("Test Button", forState: UIControlState.Normal)
        button.addTarget(self, action: "buttonAction:", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.view.addSubview(button)
    }
    
    func buttonAction(sender:UIButton!)
    {
        println("Button tapped")
       
        let testLabel = UILabel(frame: CGRectMake(0, 0, 120, 40))
        testLabel.text = "Hello, Swift!"
        testLabel
    }
}

var fb : FirstButton = FirstButton();
fb.view;
//
//let view=UIView()
////other setup
//XCPShowView("View Title",view)