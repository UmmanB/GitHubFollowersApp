//
//  Date+Ext.swift
//  GitHubFollowersApp
//
//  Created by Umman on 11.09.24.
//

import Foundation

extension Date
{
    func convertToMonthYearFormat() -> String
    {
        return formatted(.dateTime.month().year())
    }
}
