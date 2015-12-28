//
//  CatArchiveListTableViewController.swift
//  NearCat
//
//  Created by huchunbo on 15/12/25.
//  Copyright © 2015年 Bijiabo. All rights reserved.
//

import UIKit
import SwiftyJSON
import FServiceManager

class CatArchiveListTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _initViews()
        _loadCatData()
    }
    
    private func _initViews() {
        clearsSelectionOnViewWillAppear = true
        
        let tableFooterView: UIView = UIView()
        tableFooterView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = tableFooterView
        tableView.backgroundColor = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
        tableView.sendSubviewToBack(refreshControl)
    }
    
    func refresh(sender: UIRefreshControl) {
        _loadCatData {
            sender.endRefreshing()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cats.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("catItem", forIndexPath: indexPath)
        let currentData = cats[indexPath.row]
        cell.textLabel?.text = currentData["name"].stringValue

        return cell
    }

    // MARK: - data function
    var cats: [JSON] = [JSON]()
    
    private func _loadCatData(completeHandler: ()->Void = {}) {
        refreshControl?.beginRefreshing()
        
        FAction.cats.mine { (request, response, json, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshControl?.endRefreshing()
                completeHandler()
            })
        
            if error != nil {
                let errorObject: [String: String] = ["title": "读取数据失败", "message": "请下拉刷新重试"]
                NSNotificationCenter.defaultCenter().postNotificationName(Constant.Notification.Alert.showError, object: errorObject)
            } else {
                self.cats = json.arrayValue
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
            }
        }
    }

    // MARK: - segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let segueIdentifier = segue.identifier else {return}
        switch segueIdentifier {
        case "createNewCat":
            if let targetCatArchiveEditController = segue.destinationViewController as? CatArchiveEditTableViewController {
                targetCatArchiveEditController.editMode = CatArchiveEditMode.Create
            }
        case "editCat":
            if let targetCatArchiveEditController = segue.destinationViewController as? CatArchiveEditTableViewController {
                targetCatArchiveEditController.editMode = CatArchiveEditMode.Update
            }
        default:
            break
        }
    }
}
