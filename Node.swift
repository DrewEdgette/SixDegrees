//
//  Node.swift
//  SixDegrees
//
//  Created by Drew Edgette on 4/13/20.
//  Copyright © 2020 Drew Edgette's Apps LLC. All rights reserved.
//

import Foundation
import UIKit

class Node {
    var value: String
    var type: String
    var valueFormatted: String
    var edges: Array<Node>
    var discovered: Bool
    var parent: Node?
    var pictureWithAlexURL: String?
    var pictureWithAlex: UIImage?
    var location: String?
    
    // MARK: init
    init(value: String, type: String) {
        self.value = value
        self.type = type
        self.valueFormatted = value.lowercased().replacingOccurrences(of: " ", with: "")
        self.edges = []
        self.discovered = false
    }
    
    
    
    // MARK: addEdge
    // connects a node to the node
    func addEdge(theNeighbor: Node) {
        edges.append(theNeighbor)
        theNeighbor.edges.append(self)
    }
    
    
    
    // MARK: setPictureURL
    // sets the url of the image between the actor and Alex
    func setPictureURL(theURL: String) {
        self.pictureWithAlexURL = theURL
    }
    
    
    
    // MARK: setLocation
    // sets the location of the image between the actor and Alex
    func setLocation(theLocation: String?) {
        self.location = theLocation
    }
    
    
    
    // MARK: hasEdgeWith
    // checks to see if the actor is already connected
    func hasEdgeWith(theNode: Node) -> Bool {
        for neighbor in edges {
            if neighbor.valueFormatted == theNode.valueFormatted {
                return true
            }
        }
        return false
    }
    
    
    
    // MARK: fetchImage
    // takes the url and gets the corresponding image
    func fetchImage(completionHandler: (()->())?=nil) -> UIImage? {
        if pictureWithAlex != nil {
            return pictureWithAlex
        }
        
        let session = URLSession.shared
        if let urlString = pictureWithAlexURL,
            let url = URL(string: urlString)  {
            let task = session.dataTask(with: url) {
                (data, response, error) in
                
                if let actualData = data {
                    let tempPic = UIImage(data: actualData)
                    self.pictureWithAlex = tempPic
                    
                    if let actualCompletionHandler = completionHandler {
                        DispatchQueue.main.async {
                            actualCompletionHandler()
                        }
                    }
                }
            }
            task.resume()
        }
        return nil
    }
}
