//
//  UITableView+Ext.swift
//  GitHubFollowersApp
//
//  Created by Umman on 12.09.24.
//

import UIKit

extension UITableView
{
    func reloadDataOnMainThread()
    {
        DispatchQueue.main.async { self.reloadData() }
    }
    
    func removeExcessCells()
    {
        tableFooterView = UIView(frame: .zero)
    }
}
