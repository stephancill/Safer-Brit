//
//  ViewController.swift
//  Parklands Web
//
//  Created by Stephan Cilliers on 2017/05/16.
//  Copyright © 2017 Stephan Cilliers. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    var webView: WKWebView!
    
    var searchBar: UIView!
    var searchField: UITextField!
    
    var backButton: UIBarButtonItem!
    var forwardButton: UIBarButtonItem!
    var homeButton: UIButton!
    var reloadButton: UIButton!
	
	var searchLevel: SearchLevel! {
		didSet {
			UserDefaults().setValue(searchLevel.rawValue, forKey: "searchLevel")
		}
	}
	var searchLevelTableViewController: UITableViewController!
    
    var themePrimary: UIColor = #colorLiteral(red: 0.03137254902, green: 0.2666666667, blue: 0.4, alpha: 1)
    
    var progressBarView: UIView!
    
    var pageEditorSource: String!
    
    var blockedWords: [String]?
    var blockedHosts: [String]?
    
    var requests: [()->()] = []
    var requestsToComplete: Int = 0
	
	var currentSize: CGSize!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Load user settings
		if let level = UserDefaults().value(forKey: "searchLevel") as? String {
			switch level {
			case "Foundation": searchLevel = .foundation
			case "Intermediate": searchLevel = .intermediate
			case "Advanced": searchLevel = .advanced
			default:
				break
			}
		} else {
			searchLevel = .intermediate
		}
		
        // Add requests to queue
        requests = [getBlockedWords, getBlockedHosts]
        requestsToComplete = requests.count
        
        // Execute requests
		let _ = requests.map { $0() }
		
        // Starting page
		let urlString = "https://school.eb.co.uk/levels/\(searchLevel.rawValue.lowercased())"
        let myURL = URL(string: urlString)
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        
        setupNavigationBar()
    }
	
    override func loadView() {
        super.loadView()
		
        // Create WebView
        webView = WKWebView(frame: .zero)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view = webView
    }
	
	/* External resources */
	
	func getBlockedWords() {
		/*
		-    Fetch words to be censored
		*/
		let endpoint = URL(string: "https://cdn.rawgit.com/stephancill/Parklands-Web/38650c09/blocked-words.txt")
		
		URLSession.shared.dataTask(with: endpoint!) { (data, response, error) in
			var words = String.init(data: data!, encoding: .utf8)?.components(separatedBy: "\n")
			let _ = words?.popLast()
			self.blockedWords = words
			self.asyncRequestComplete(error: error)
		}.resume()
	}
	
	func getBlockedHosts() {
		/*
		-    Fetch blocked hosts
		*/
		let endpoint = URL(string: "https://cdn.rawgit.com/stephancill/Parklands-Web/38650c09/blocked-hosts.txt")
		
		URLSession.shared.dataTask(with: endpoint!) { (data, response, error) in
			var hosts = String.init(data: data!, encoding: .utf8)?.components(separatedBy: "\n")
			let _ = hosts?.popLast()
			self.blockedHosts = hosts
			self.asyncRequestComplete(error: error)
		}.resume()
	}
	
	
	
	func asyncRequestComplete(error: Error?) {
		/*
		-    Handle complete request
		*/
		if error != nil {  return }
		requestsToComplete -= 1
		print("Requests remaining: ", requestsToComplete)
		if requestsToComplete == 0 {
			if let source = createPageEditorScript() {
				DispatchQueue.main.async {
					// Add source to webView
					let scriptPostLoad = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
					self.webView.configuration.userContentController.addUserScript(scriptPostLoad)
					self.webView.configuration.userContentController.add(self, name: "enableUserInteraction")
					self.webView.configuration.userContentController.add(self, name: "disableUserInteraction")
				}
			}
		}
	}
	
	func createPageEditorScript() -> String? {
		/*
		-    Populate the JS base script with external resources
		*/
		guard let hosts = blockedHosts, let words = blockedWords else {
			return nil
		}
		
		var source = ""
		source += "var words = \(words)\n"
		source += "var hosts = \(hosts)\n"
		do {
			if let path = Bundle.main.path(forResource: "page-editor", ofType:"js") {
				source += try String.init(contentsOf: URL(fileURLWithPath: path))
				return source
			} else {
				throw ScriptCreationError.creationFailure
			}
		} catch {
			print("Could not load words")
		}
		return nil
	}
    
    /* UI */
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.tearDownNavigationBar()
        self.setupNavigationBar()
    }
	
	/* Progress Bar */
    func startProgressBar() {
        progressBarView.backgroundColor = #colorLiteral(red: 0.03137254902, green: 0.2666666667, blue: 1, alpha: 1)
        progressBarView.setWidth(0)
        UIView.animate(withDuration: 2) {
            self.progressBarView.setWidth(self.view.frame.width - 100)
        }
    }
    
    func completeProgressBar() {
        UIView.animate(withDuration: 0.5) {
            self.progressBarView.setWidth(self.view.frame.width)
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.progressBarView.backgroundColor = .clear
        }) { (bool) in
            self.progressBarView.setWidth(0)
        }
    }
    
    func cancelProgressBar() {
        UIView.animate(withDuration: 0.5, animations: {
            self.progressBarView.backgroundColor = .clear
        }) { (bool) in
            self.progressBarView.setWidth(0)
        }
    }
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		
	}
	
	func setupNavigationBar() {
		let bar = (self.navigationController?.navigationBar)!
		
		searchBar = UIView(frame: CGRect.init(x: 0, y: 0, width: 500, height: 30))
		
		if self.view.frame.width < 600 {
			searchBar.setWidth(self.view.frame.width * 40/100)
		}
		searchBar.frame.origin = CGPoint(x: bar.frame.width / 2 - searchBar.frame.width / 2, y: bar.frame.height / 2 - searchBar.frame.height / 2)
		searchBar.backgroundColor = .white
		searchBar.layer.cornerRadius = 7
		searchBar.layer.opacity = 0.75
		searchBar.layer.borderColor = themePrimary.cgColor
		searchBar.layer.shadowOffset = CGSize(width: 1, height: 1)
		searchBar.layer.shadowRadius = 2
		searchBar.layer.shadowColor = UIColor.gray.cgColor
		searchBar.layer.shadowOpacity = 0.0
		
		if self.view.frame.width < 600 {
			searchBar.setWidth(self.view.frame.width * 60/100)
		}
		
		searchField = UITextField(frame: CGRect.init(x: 0, y: 0, width: searchBar.frame.width * 95/100, height: 30))
		searchField.backgroundColor = .clear
		searchField.frame.origin = CGPoint(x: searchBar.frame.width / 2 - searchField.frame.width / 2, y: searchBar.frame.height / 2 - searchField.frame.height / 2)
		searchField.autocorrectionType = .no
		searchField.autocapitalizationType = .none
		searchField.keyboardType = .webSearch
		searchField.placeholder = "Search..."
		searchField.textAlignment = .center
		searchField.delegate = self
		searchBar.addSubview(searchField)
		
		backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(goBack))
		backButton.tintColor = themePrimary
		backButton.isEnabled = false
		self.navigationItem.setLeftBarButton(backButton, animated: true)
		
		forwardButton = UIBarButtonItem(title: "Forward", style: .plain, target: self, action: #selector(goForward))
		forwardButton.tintColor = themePrimary
		forwardButton.isEnabled = false
		self.navigationItem.setRightBarButton(forwardButton, animated: true)
		
		//
		homeButton = UIButton(frame: CGRect.init(x: 0, y: 0, width: searchBar.frame.height * 100/100, height: searchBar.frame.height * 100/100))
		homeButton.frame.origin = CGPoint(x: searchBar.frame.minX - homeButton.frame.width - 12, y: searchBar.frame.height / 2 - homeButton.frame.height / 2 + 7)
		homeButton.setImage(UIImage.init(named: "icn-level")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
		homeButton.addTarget(self, action: #selector(homeButtonPressed(sender:)), for: .touchUpInside)
		homeButton.tintColor = themePrimary
		print()
		
		
		reloadButton = UIButton(frame: CGRect.init(x: 0, y: 0, width: searchBar.frame.height * 96/100, height: searchBar.frame.height * 96/100))
		reloadButton.frame.origin = CGPoint(x: searchBar.frame.maxX + reloadButton.frame.width - 20, y: searchBar.frame.height / 2 - reloadButton.frame.height / 2 + 6)
		reloadButton.setImage(UIImage.init(named: "icn-reload")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate), for: .normal)
		reloadButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
		reloadButton.tintColor = themePrimary
		
		progressBarView = UIView(frame: CGRect.init(x: 0, y: searchBar.frame.maxY + 6, width: bar.frame.width, height: 3))
		progressBarView.setWidth(0)
		
		bar.barStyle = .default
		bar.tintColor = themePrimary
		bar.backgroundColor = themePrimary
		
		// Add subviews
		[searchBar, homeButton, reloadButton, progressBarView].forEach { bar.addSubview($0) }
	}
	
	func tearDownNavigationBar() {
		for view in [searchBar, homeButton, reloadButton, progressBarView] {
			view?.removeFromSuperview()
		}
	}
	
	func homeButtonPressed(sender: UIBarButtonItem) {
		let searchLevelVC = SearchLevelTableViewController()
		searchLevelVC.title = "Search Level"
		searchLevelVC.delegate = self
		searchLevelVC.searchLevel = self.searchLevel
		
		searchLevelVC.modalPresentationStyle = .popover
		searchLevelVC.popoverPresentationController?.sourceView = homeButton
		searchLevelVC.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: homeButton.frame.width, height: homeButton.frame.height)
		
		self.present(searchLevelVC, animated: true, completion: nil)
	}
}

extension ViewController: WKUIDelegate, WKNavigationDelegate, WebViewTouchDelegate {
	/* WebKit */
	func goBack() {
		webView.isUserInteractionEnabled = true
		self.webView.goBack()
	}
	
	func goForward() {
		self.webView.goForward()
	}
	
	func goHome() {
		self.searchField.text = ""
		let urlString = "https://school.eb.co.uk/levels/\(searchLevel.rawValue.lowercased())"
		if webView.url?.absoluteString != urlString {
			// Starting page
			let myURL = URL(string: urlString)
			let myRequest = URLRequest(url: myURL!)
			webView.load(myRequest)
		}
	}
	
	func reload() {
		self.webView.load(URLRequest.init(url: self.webView.url!))
	}
	
	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
		print("committed")
		
		let url = webView.url?.absoluteString
		
		if url!.contains("school.eb.co.uk/levels") {
			let separatedUrl = webView.url!.absoluteString.components(separatedBy: "/")
			print(separatedUrl)
			if separatedUrl.count >= 5 {
				switch separatedUrl[4].lowercased() {
				case "foundation": searchLevel = .foundation
				case "intermediate": searchLevel = .intermediate
				case "advanced": searchLevel = .advanced
				default: break
				}
			}
		}
		
		//[1].components(separatedBy: "/")[2]
		backButton.isEnabled = webView.canGoBack
		forwardButton.isEnabled = webView.canGoForward
		
		startProgressBar()
	}
	
	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		print(error)
		cancelProgressBar()
		if (webView.canGoBack) {
			webView.goBack()
		}
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		print("finished")
		
		completeProgressBar()
	}
	
	func touchesBegan(webView: WKWebView) {
		self.searchField.endEditing(true)
	}
}

extension ViewController: WKScriptMessageHandler {
	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		print("hello")
		switch message.name {
		case "enableUserInteraction":
			webView.isUserInteractionEnabled = true
		case "disableUserInteraction":
			webView.isUserInteractionEnabled = false
		default:
			return
		}
	}
}

extension ViewController: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectAll(self)
		searchBar.layer.shadowOpacity = 0.3
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let text = textField.text!
		let escapedAddress = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
		let queryString = "https://school.eb.co.uk/levels/\(searchLevel.rawValue.lowercased())/search/articles?query=\(escapedAddress!)"
		print(queryString)
		//https://school.eb.co.uk/levels/intermediate/search/articles?query=asdf
		startProgressBar()
		webView.load(queryString)
		textField.endEditing(true)
		return true
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.textAlignment = .center
	}
	
	func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
		searchBar.layer.shadowOpacity = 0
	}
}

enum ScriptCreationError: Error {
	case creationFailure
}
