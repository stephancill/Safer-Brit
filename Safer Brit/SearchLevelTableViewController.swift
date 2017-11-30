//
//  SearchLevelTableViewController.swift
//  Parklands Web
//
//  Created by Stephan Cilliers on 2017/11/30.
//  Copyright © 2017 Stephan Cilliers. All rights reserved.
//

import UIKit

class SearchLevelTableViewController: UITableViewController {
	
	var searchLevels: [SearchLevel] = [.foundation, .intermediate, .advanced]
	var searchLevel: SearchLevel!
	var delegate: ViewController!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.preferredContentSize = CGSize(width: 250, height: 250)
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // Configure the cell...
		cell.textLabel?.text = searchLevels[indexPath.row].rawValue
		
		if searchLevel == searchLevels[indexPath.row] {
			cell.accessoryType = .checkmark
		}

        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		for i in 0..<tableView.numberOfRows(inSection: 0) {
			self.tableView.cellForRow(at: IndexPath(row: i, section: 0))?.accessoryType = .none
		}
		
		self.tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
		self.tableView.deselectRow(at: indexPath, animated: true)
		self.delegate.searchLevel = searchLevels[indexPath.row]
		self.dismiss(animated: true) {
			self.delegate.goHome()
		}
	}
}


enum SearchLevel: String {
	case foundation = "Foundation"
	case intermediate = "Intermediate"
	case advanced = "Advanced"
}
