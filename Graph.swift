//
//  Graph.swift
//  SixDegrees
//
//  Created by Drew Edgette on 4/13/20.
//  Copyright © 2020 Drew Edgette's Apps LLC. All rights reserved.
//

import Foundation

class Graph {
    var nodeDict: [String:Node]
    
    // MARK: - init
    init() {
        // sets up an empty dictionary for the nodes and then populates it with data
        nodeDict = [:]
    } // init
    
    
    
    // MARK: - addNode
    // adds a node to nodeDict
    func addNode(theNode: Node) {
        let title = theNode.valueFormatted
        nodeDict[title] = theNode
    }
    

    
    // MARK: - getNode
    // gets a node by its key
    func getNode(theValue: String) -> Node? {
        if let node = nodeDict[theValue.lowercased().replacingOccurrences(of: " ", with: "")] {
            return node
        }
        return nil
    }
    
    
    
    // MARK: - BFS
    // breadth-first search to find two actors in the movie data
    func bfs(theActor: String) -> Array<Node>? {
        var theQueue = [Node]()
        
        // if the actor is in the graph, carry on with BFS
        if let startNode = getNode(theValue: theActor) {
            
            // label the actor as discovered and add it to the queue
            startNode.discovered = true
            theQueue.append(startNode)
            
            // search for Alex until there's nothing left in the queue
            while theQueue.count > 0 {
                let currentNode = theQueue[0]
                theQueue.removeFirst()
                
                // if they have taken a picture with alex, we're done.
                if currentNode.pictureWithAlexURL != nil {
                    return getParentPath(startNode: currentNode)
                }
                
                // else check all of the node's neighbors for Alex
                for neighbor in currentNode.edges {
                    if !neighbor.discovered {
                        neighbor.discovered = true
                        neighbor.parent = currentNode
                        theQueue.append(neighbor)
                    }
                }
            }
        }
        
      // if we got here, the searched actor isn't in the graph.
      // (or everyone in the cast has only worked with each other)
      return nil
    }
    
    
    
    // MARK: - getParentPath
    // retrieves the shortest path between the searched actor and Alex after doing BFS
    func getParentPath(startNode: Node) -> Array<Node> {
        var thePath = [startNode]
        var parentNode = startNode.parent
        
        while parentNode != nil {
            thePath.append(parentNode!)
            parentNode = parentNode?.parent
        }
        return thePath.reversed()
    }
    
    
    
    // MARK: - resetNodes
    // resets parent and discovered value for all nodes
    func resetNodes() {
        for (_, node) in nodeDict {
            node.discovered = false
            node.parent = nil
        }
    }
    
    
    
    // MARK: - readFile
    // read local file
    func readFile(fileName: String, fileType: String) -> String {
               // opens up the movie data file
               let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
               let fileURL = DocumentDirURL.appendingPathComponent(fileName).appendingPathExtension(fileType)
        
               let fileURLProject = Bundle.main.path(forResource: fileName, ofType: fileType)

               // puts the movie data into a string
               var readStringProject = ""
               
               do {
                   readStringProject = try String(contentsOfFile: fileURLProject!, encoding: String.Encoding.utf8)
               }
                   
               catch let error as NSError {
                   print("Failed reading from URL: \(fileURL), Error: " + error.localizedDescription)
               }
        
        return readStringProject
    }
    
    
    
    // MARK: - createMovieNodes
    // opens up a local json with movie data and adds actors and movies to nodeDict
    func createMovieNodes() {
        // gets the movie data from local JSON
        let movieDataString = readFile(fileName: "moviedata", fileType: "txt")
        
        // takes the string containing the movie data and turns it into a JSON data type
               if let dataFromString = movieDataString.data(using: .utf8, allowLossyConversion: false),
               let parsedData = try? JSON(data: dataFromString) {
                   
                   // creates a node for every movie in the dataset
                   for (_,movie):(String, JSON) in parsedData {
                       if let title = movie["title"].string,
                       let cast = movie["cast"].array {
                        let movieNode = Node(value: title, type: "movie")
                           addNode(theNode: movieNode)
                           
                           // creates a node for every actor in the dataset
                           for person in cast {
                               if let actor = person.string {
                                   
                                   // if we already have that actor in the graph, only add the movie edge
                                   if let existingActorNode = getNode(theValue: actor) {
                                       movieNode.addEdge(theNeighbor: existingActorNode)
                                       continue
                                   }
                                       
                                   // if we don't have them yet, create a new actor node and add it to the graph
                                let newActorNode = Node(value: actor, type: "actor")
                                   addNode(theNode: newActorNode)
                                   movieNode.addEdge(theNeighbor: newActorNode)
                               }
                           }
                       }
                   }
               }
    }
    
    
    
    // MARK: - createInstagramNodes
    // opens up a local txt with links to JSON files and adds connections to Alex
    func createInstagramNodes() {
        // adds the star of our show to the node dictionary
        let alexNode = Node(value: "Alexandre Nihous", type: "actor")
        addNode(theNode: alexNode)
        
        // gets the api endpoint info from a local file and turns it into an list
        // each endpoint is a JSON file
        let imageLinkString = readFile(fileName: "imageLinks", fileType: "txt")
        let imageLinkArray = imageLinkString.split(separator: "\r\n")
        
        // for each link, create a URL session to grab the data out of it
        for link in imageLinkArray {
            let baseURL = String(describing: link)
            let url = URL(string: baseURL)!
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                
               if let actualError = error {
                   print("we got an error, boys")
               }
                
                
               else if let actualData = data, let actualResponse = response,
               let parsedData = try? JSON(data: actualData),
               let edges = parsedData["data"]["user"]["edge_owner_to_timeline_media"]["edges"].array {
                
                
                    // for each post in the JSON, check to see if the picture is with a famous actor
                    
                    for node in edges {
                        if let taggedActors = node["node"]["edge_media_to_tagged_user"]["edges"].array,
                        let pictureURL = node["node"]["display_url"].string {
                            
                            let location = node["node"]["location"]["name"].string
            
                            
                            for actor in taggedActors {
                                if let fullName = actor["node"]["user"]["full_name"].string {
                                    // if we already have that actor in the graph, only add the edge to alex
                                    if let existingActorNode = self.getNode(theValue: fullName) {
                                        if alexNode.hasEdgeWith(theNode: existingActorNode) {
                                            continue
                                        }
                                        alexNode.addEdge(theNeighbor: existingActorNode)
                                        existingActorNode.setPictureURL(theURL: pictureURL)
                                        existingActorNode.setLocation(theLocation: location)
                                        
                                        
                                        continue
                                    }
                                    
                                    // if we don't have them yet, create a new actor node and add it to the graph
                                    let newActorNode = Node(value: fullName, type: "actor")
                                    self.addNode(theNode: newActorNode)
                                    newActorNode.setPictureURL(theURL: pictureURL)
                                    newActorNode.setLocation(theLocation: location)
                            }
                        }
                            
                            // there are no tagged actors. Looking through hashtags instead
                            if taggedActors.count == 0 {
                                if let theCaption = node["node"]["edge_media_to_caption"]["edges"][0]["node"]["text"].string {
                                    let theCaptionLC = theCaption.lowercased()
                                    if theCaptionLC.contains("with ") {
                                        var theHashtags = theCaptionLC.components(separatedBy: " ")
                                        theHashtags.removeAll() {!$0.contains("#")}
                                        theHashtags.removeAll() {$0.contains(".")}
                                        
                                        if theHashtags.count > 0 {
                                            var fullName = theHashtags[0]
                                            fullName.remove(at: fullName.startIndex)
                                            
      
                                            // if we already have that actor in the graph, only add the edge to alex
                                            if let existingActorNode = self.getNode(theValue: fullName) {
                                                if existingActorNode.type == "movie" {
                                                    continue
                                                }
                                                if alexNode.hasEdgeWith(theNode: existingActorNode) {
                                                    continue
                                                }
                                                alexNode.addEdge(theNeighbor: existingActorNode)
                                                existingActorNode.setPictureURL(theURL: pictureURL)
                                                existingActorNode.setLocation(theLocation: location)
                                                continue
                                            }
                                        }
                                    }
                                }
                            }
                        }
                }
            }
        }
            task.resume()
        }
    }
    
    
    func shuffledNodes() -> Array<String> {
        let rdmNodeDict = nodeDict.shuffled()
        var rdmNodeArray = Array<String>()

        for (_,value) in rdmNodeDict {
            if value.type == "actor" {
                rdmNodeArray.append(value.value)
            }
        }
        return rdmNodeArray
    }
}

// MARK: ZUCKERBERG: SMELLS:
