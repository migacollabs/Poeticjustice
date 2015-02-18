//
//  AvatarPicCollectionViewController.swift
//  PoeticJusticeApp
//
//  Created by Mat Mathews on 2/8/15.
//  Copyright (c) 2015 Miga Col.Labs. All rights reserved.
//

import UIKit

let reuseIdentifier = "Cell"

class AvatarPicCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var avatar = Avatar()
    
    var selectedColour = UIColor(red:0.67, green:0.93, blue:0.94, alpha:1.0)
    
    var selectedIndexPathRow: Int = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        self.collectionView?.allowsSelection = true
        self.collectionView?.allowsMultipleSelection = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return 30
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        println("cellForItemAtIndexPath called")
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as UICollectionViewCell
    
        // Configure the cell
        
        if let avatarCell = cell as? AvatarPicCollectionViewCell{
            avatarCell.imageView.image = UIImage(named: self.avatar.get_avatar_file_name(indexPath.row)!)
            
        }else{
            cell.backgroundColor = UIColor.blackColor()
        }
        
        if self.selectedIndexPathRow == indexPath.row{
            cell.backgroundColor = self.selectedColour
        }else{
            cell.backgroundColor = UIColor.whiteColor()
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        var cell = collectionView.cellForItemAtIndexPath(indexPath)
        if self.selectedIndexPathRow == indexPath.row{
            cell!.backgroundColor = self.selectedColour
        }else{
            cell!.backgroundColor = UIColor.whiteColor()
        }
        NetOpers.sharedInstance.user.avatarName = self.avatar.get_avatar_file_name(indexPath.row)!
    }

    
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if self.selectedIndexPathRow > -1 && self.selectedIndexPathRow != indexPath.row{
            var prevIndexPath = NSIndexPath(forRow:self.selectedIndexPathRow, inSection:0)
            var cell = collectionView.cellForItemAtIndexPath(prevIndexPath)
            cell?.backgroundColor = UIColor.whiteColor()
        }
        self.selectedIndexPathRow = indexPath.row
        return true
    }
    

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView!,
        layout collectionViewLayout: UICollectionViewLayout!,
        sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
            
            return CGSize(width:200, height:200)
    }

}





















