var node, next;

//var element = document.getElementsByClassName("gsc-adBlock")[0];
//console.log(element)
//element.parentNode.removeChild(element);
//document.getElementsByClassName("gsc-adBlock")[0].style.display = "none"

console.log("faggot")

// Remove ads
window.onload = function () {
	var element = document.getElementsByClassName("gsc-adBlock")[0];
	element.parentNode.removeChild(element);
	var element = document.getElementById("adBlock");
	element.parentNode.removeChild(element);
	console.log("hello")
	document.getElementsByClassName("gsc-adBlock")[0].style.display = "none"
}


// Block other search providers
hosts.map(host => {
	if (window.location.hostname.indexOf(host) > -1) {
	  document.body.innerHTML = "<h1>Blocked :(</h1>"
	  return
	}
})

// Walk the dom looking for the given text in text nodes
walk(document.body);

// Insert the result into the current document via a fragment
node = document.body.firstChild;
while (node) {
	next = node.nextSibling;
	frag.appendChild(node);
	node = next;
}
document.body.appendChild(frag);

// Our walker function
function walk(node) {
	var child, next;
	
	switch (node.nodeType) {
		case 1:  // Element
		case 9:  // Document
		case 11: // Document fragment
			child = node.firstChild;
			while (child) {
				next = child.nextSibling;
				walk(child);
				child = next;
			}
			break;
		case 3: // Text node
			handleText(node);
			break;
	}
}

function handleText(textNode) {
	words.map(word => {
		textNode.nodeValue = textNode.nodeValue.replace(new RegExp(`${word}`, "gi"), "!@#$%");
	})
}
