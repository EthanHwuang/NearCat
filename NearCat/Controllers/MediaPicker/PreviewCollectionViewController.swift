//
//  PreviewCollectionViewController.swift
//  NCPhotoViewer
//
//  Created by huchunbo on 16/1/21.
//  Copyright © 2016年 Bijiabo. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "photoCell"
private let numberOfCellsInLine: Int = 5
private let cellSpacing: CGFloat = 4.0

class PreviewCollectionViewController: UICollectionViewController {
    
    var momentMode: Bool = false
    var assetsCollection: PHAssetCollection?
    var data: PHFetchResult!
    var subData: [PHFetchResult] = [PHFetchResult]()
    let flowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
    var mediaPickerDelegate: MediaPickerDelegate?
    
    var selectedImageIndexPaths:  [NSIndexPath] = [NSIndexPath]() {
        didSet {
            counterView?.text = "\(selectedImageIndexPaths.count)"
        }
    }
    var selectedImages: [UIImage] = [UIImage]()
    var counterView: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _setupData()
        
        // setup flow layout
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        flowLayout.scrollDirection = UICollectionViewScrollDirection.Vertical
        flowLayout.minimumInteritemSpacing = cellSpacing
        flowLayout.minimumLineSpacing = cellSpacing
        flowLayout.sectionInset = UIEdgeInsets(top: cellSpacing, left: cellSpacing, bottom: cellSpacing, right: cellSpacing)
        if momentMode {
            flowLayout.headerReferenceSize = CGSize(width: view.frame.width, height: 50.0)
            if #available(iOS 9.0, *) {
                flowLayout.sectionHeadersPinToVisibleBounds = true
            } else {
                // Fallback on earlier versions
            }
        }
        collectionView?.collectionViewLayout = flowLayout

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        
        // scroll to latest photo
        let latestSectionIndex = momentMode ? (data.count > 1 ? data.count - 1 : 0) : 0
        let latestRowIndex = momentMode ? (subData.isEmpty ? 0 : (subData.last!.count > 1 ? subData.last!.count - 1 : 0)) : (data.count > 1 ? data.count - 1 : 0)
        let latestIndexPath = NSIndexPath(forRow: latestRowIndex, inSection: latestSectionIndex)
        collectionView?.scrollToItemAtIndexPath(latestIndexPath, atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: false)
        
        // setup navigation bar buttons
        counterView = UILabel(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        counterView?.text = "0"
        Helper.UI.setLabel(counterView!, forStyle: Constant.TextStyle.Cell.Small.White)
        counterView?.textAlignment = .Center
        counterView?.textColor = UIColor.whiteColor()
        counterView?.backgroundColor = Constant.Color.Theme
        counterView?.layer.cornerRadius = 10.0
        counterView?.clipsToBounds = true
        let counterButton = UIBarButtonItem(customView: counterView!)
        let okButton = UIBarButtonItem(title: "确定", style: UIBarButtonItemStyle.Done, target: self, action: Selector("tapDoneButton:"))
        
        navigationItem.rightBarButtonItems = [okButton, counterButton]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if _hasBeenDisapper {
            collectionView?.reloadItemsAtIndexPaths(selectedImageIndexPaths)
        }
    }
    
    private var _hasBeenDisapper: Bool = false
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        _hasBeenDisapper = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: user action
    
    func tapDoneButton(sender: AnyObject) {
        
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
        // #warning Incomplete implementation, return the number of sections
        if momentMode {
            return data.count
        } else {
            return 1
        }
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if momentMode {
            return subData[section].count
        } else {
            return data.count
        }
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PreviewPhotoCollectionViewCell
        let currentAsset = momentMode ? subData[indexPath.section].objectAtIndex(indexPath.row) as! PHAsset : data.objectAtIndex(indexPath.row) as! PHAsset
        
        let targetSize = CGSize(width: 120.0, height: 120.0)

        dispatch_async(Helper.MultiThread.Queue.Serial) { () -> Void in
            PHImageManager.defaultManager().requestImageForAsset(currentAsset, targetSize: targetSize, contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image, info: [NSObject : AnyObject]?) -> Void in
                guard let image = image else {return}
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    cell.image = image
                })
            })
        }
        
        if selectedImageIndexPaths.contains(indexPath) {
            cell.select = true
        } else {
            cell.select = false
        }
        
        cell.indexPath = indexPath
        cell.delegate = self
    
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "previewHeaderCell", forIndexPath: indexPath) as! PreviewHeaderCollectionReusableView
            if let currentCollection = data.objectAtIndex(indexPath.section) as? PHAssetCollection {
                let startDateString: String = currentCollection.startDate == nil ? "" : _formatDate(currentCollection.startDate!)
                let endDateString: String = currentCollection.endDate == nil ? "" : _formatDate(currentCollection.endDate!)
                let collectionName = currentCollection.localizedLocationNames.count > 0 ? currentCollection.localizedLocationNames.first : currentCollection.localizedTitle
                if let collectionName = collectionName {
                    headerView.title = startDateString.isEmpty || endDateString.isEmpty ? collectionName : "\(collectionName) (\(startDateString) - \(endDateString))"
                } else {
                    headerView.title = startDateString.isEmpty || endDateString.isEmpty ? "Moment" : "\(startDateString) - \(endDateString)"
                }
            }
            
            return headerView
        }
        
        let reusableView: UICollectionReusableView! = nil
        return reusableView
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let segueIdentifier = segue.identifier else {return}
        switch segueIdentifier {
        case "linkToBrowse":
            guard let targetVC = segue.destinationViewController as? BrowseCollectionViewController else {return}
            guard let cell = sender as? PreviewPhotoCollectionViewCell else {return}
            guard let indexPath = collectionView?.indexPathForCell(cell) else {return}
            
            targetVC.mediaPickerDelegate = self.mediaPickerDelegate
            targetVC.selectedImages = selectedImages
            targetVC.selectedImageIndexPaths = selectedImageIndexPaths
            targetVC.previewCollectionVC = self
            
            if momentMode {
                targetVC.assetsCollection = data.objectAtIndex(indexPath.section) as? PHAssetCollection
                targetVC.startIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
            } else {
                targetVC.assetsCollection = assetsCollection
                targetVC.startIndexPath = indexPath
            }
        default:
            break
        }
    }
    
    private func _formatDate(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        return dateFormatter.stringFromDate(date)
    }
    
    // MARK: delegate function
    
    func tapSelectButton(indexPath indexPath: NSIndexPath) {
        
        guard let cell = collectionView?.cellForItemAtIndexPath(indexPath) as? PreviewPhotoCollectionViewCell else {return}
        
        if selectedImageIndexPaths.contains(indexPath) {
            selectedImageIndexPaths.removeAtIndex(selectedImageIndexPaths.indexOf(indexPath)!)
            cell.select = false
        } else {
            selectedImageIndexPaths.append(indexPath)
            cell.select = true
            
            // get image
            let currentAsset = momentMode ? subData[indexPath.section].objectAtIndex(indexPath.row) as! PHAsset : data.objectAtIndex(indexPath.row) as! PHAsset
            let targetSize = CGSize(width: 120.0, height: 120.0)
            PHImageManager.defaultManager().requestImageForAsset(currentAsset, targetSize: targetSize, contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image, info: [NSObject : AnyObject]?) -> Void in
                guard let image = image else {return}
                
                self.selectedImages.append(image)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                })
                
            })
        }
    }

}

// MARK: - data functions

extension PreviewCollectionViewController {
    
    private func _setupData() {
        if momentMode {
            let userMomentsOptions: PHFetchOptions = PHFetchOptions()
            userMomentsOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0", argumentArray: nil)
            let userMoments: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Moment, subtype: PHAssetCollectionSubtype.AlbumRegular, options: userMomentsOptions)
            data = userMoments
            
            var subDataCache: [PHFetchResult] = [PHFetchResult]()
            data.enumerateObjectsUsingBlock({ (collection, index, stop) -> Void in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [
                    NSSortDescriptor(key: "creationDate", ascending: true)
                ]
                subDataCache.append( PHAsset.fetchAssetsInAssetCollection(collection as! PHAssetCollection, options: fetchOptions) )
            })
            subData = subDataCache
            
        } else {
            guard let assetsCollection = assetsCollection else {return}
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: true)
            ]
            data = PHAsset.fetchAssetsInAssetCollection(assetsCollection, options: fetchOptions)
        }
    }
}

// MARK: - flow layout delegate

extension PreviewCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let x = (view.frame.size.width - CGFloat(numberOfCellsInLine + 2) * flowLayout.minimumLineSpacing  ) / CGFloat(numberOfCellsInLine)
        return CGSize(width: x, height: x)
    }
}