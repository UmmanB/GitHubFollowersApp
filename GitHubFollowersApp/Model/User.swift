//
//  User.swift
//  GitHubFollowersApp
//
//  Created by Umman on 03.09.24.
//

import Foundation

struct User: Codable
{
    var login: String
    var avatarUrl: String
    var name: String?
    var location: String?
    var bio: String?
    var publicRepos: Int
    var publicGists: Int
    var htmlUrl: String
    var following: Int
    var followers: String
    var createdAt: String
}
