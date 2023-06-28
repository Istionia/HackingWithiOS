//
//  ViewController.swift
//  WordScrambleUI
//
//  Created by Timothy on 11/05/2023.
//

import UIKit

class ViewController: UITableViewController {
    var allWords = [String]()
    var usedWords = [String]()
    var currentWord = ""
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // try? means "call this code, and if it throws an error just send me back nil instead." This means the code you call will always work, but you need to unwrap the result carefully.
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        // isEmpty returns true if the array is empty, and is effectively equal to writing allWords.count == 0. The reason we use isEmpty is because some collection types, such as string, have to calculate their size by counting over all the elements they contain, so reading count == 0 can be significantly slower than using isEmpty.
        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
        
        loadSavedData()
    }

    private func loadSavedData() {
        if let currentWord = defaults.string(forKey: "Current word") {
            self.currentWord = currentWord
            title = currentWord
        } else {
            startGame()
        }
        
        if usedWords == defaults.object(forKey: "Used words") as? [String] ?? [String]() {
            tableView.reloadData()
        } else {
            startGame()
        }
    }
    
    func startGame() {
        title = currentWord
        currentWord = allWords.randomElement() ?? "silkworm"
        defaults.set(currentWord, forKey: "Current word")
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        defaults.set(usedWords, forKey: "Used words")
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    // It needs to be called from a UIBarButtonItem action, so we must mark it @objc. Hopefully you’re starting to sense when this is needed, but don’t worry if you forget – Xcode will always complain loudly if @objc is required and not present!
    @objc func promptForAnswer() {
        // The addTextField() method just adds an editable text input field to the UIAlertController. We could do more with it, but it's enough for now.
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        // UITextField is a simple editable text box that shows the keyboard so the user can enter something. We added a single text field to the UIAlertController using its addTextField() method, and we now read out the value that was inserted.
        // trailing closure syntax (rather than specifying a handler parameter, we pass the code we want to run in braces after the method call)
        // that's what's happening here: we're giving the UIAlertAction some code to execute when it is tapped, and it wants to know that that code accepts a parameter of type UIAlertAction.
        // The in keyword is important: everything before that describes the closure; everything after that is the closure. So action in means that it accepts one parameter in, of type UIAlertAction.
        // In our current project, we could simplify this even further: we don't make any reference to the action parameter inside the closure, which means we don't need to give it a name at all. In Swift, to leave a parameter unnamed you just use an underscore character
        // weak: Swift "captures" any constants and variables that are used in a closure, based on the values of the closure's surrounding context. That is, if you create an integer, a string, an array and another class outside of the closure, then use them inside the closure, Swift captures them.
        // This is important, because the closure references the variables, and might even change them. But what does "capture" actually means? It depends what kind of data you're using. Fortunately, Swift hides it all away so you don't have to worry about it…
        // …except for those strong reference cycles. Those you need to worry about. That's where objects can't even be destroyed because they all hold tightly on to each other – known as strong referencing.
        // Swift's solution is to let you declare that some variables aren't held onto quite so tightly. It's a two-step process, and it's so easy you'll find yourself doing it for everything just in case. In the event that Xcode thinks you’re taking it a bit too far, you’ll get a warning saying you can relax a bit.
        // First, you must tell Swift what variables you don't want strong references for. This is done in one of two ways: unowned or weak. These are somewhat equivalent to implicitly unwrapped optionals (unowned) and regular optionals (weak): a weakly owned reference might be nil, so you need to unwrap it or use optional chaining; an unowned reference is one you're certifying cannot be nil and so doesn't need to be unwrapped, however you'll hit a problem if you were wrong.
        // In our code we use this: [weak self, weak ac]. That declares self (the current view controller) and ac (our UIAlertController) to be captured as weak references inside the closure. It means the closure can use them, but won't create a strong reference cycle because we've made it clear the closure doesn't own either of them.
        // But that's not enough for Swift. Inside our method we're calling the submit() method of our view controller. We haven't created it yet, but you should be able to see it's going to take the answer the user entered and try it out in the game.
        // This submit() method is external to the closure’s current context, so when you're writing it you might not realize that calling submit() implicitly requires that self be captured by the closure. That is, the closure can't call submit() if it doesn't capture the view controller.
        // We've already declared that self is weakly owned by the closure, but Swift wants us to be absolutely sure we know what we're doing: every call to a method or property of the current view controller must prefixed with "self?.”, as in self?.submit().
        //  Two trains of thought regarding use of self, and said, "The first group of people never like to use self. unless it's required, because when it's required it's actually important and meaningful, so using it in places where it isn't required can confuse matters."
        // Implicit capture of self in closures is that place when using self is required and meaningful: Swift won't let you avoid it here. By restricting your use of self to closures you can easily check your code doesn’t have any reference cycles by searching for "self" – there ought not to be too many to look through!
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] action in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        
        // The addAction() method is used to add a UIAlertAction to a UIAlertController.
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        
        let errorTitle: String
        let errorMessage: String
        
        if isPossible(word: lowerAnswer) {
            if isOriginal(word: lowerAnswer) {
                if isReal(word: lowerAnswer) {
                    usedWords.insert(answer, at: 0)
                    
                    let indexPath = IndexPath(row: 0, section: 0)
                    tableView.insertRows(at: [indexPath], with: .automatic)
                    
                    return
                } else {
                    errorTitle = "Word not recognised"
                    errorMessage = "Making them up, already? You can do better than that."
                }
            } else {
                errorTitle = "This word has been used already!"
                errorMessage = "Some originality would be more becoming..."
            }
        } else {
            guard let title = title?.lowercased() else { return }
            errorTitle = "Word not possible"
            errorMessage = "You can't spell that word from \(title)."
        }
    
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    // As you can see, every if statement now has a matching else statement so that the user gets appropriate feedback. All the elses are effectively the same (albeit with changing text): set the values for errorTitle and errorMessage to something useful for the user. The only interesting exception is the last one, where we use string interpolation to show the view controller's title as a lowercase string.
    // If the user enters a valid answer, a call to return forces Swift to exit the method immediately once the table has been updated. This is helpful, because at the end of the method there is code to create a new UIAlertController with the error title and message that was set, add an OK button without a handler (i.e., just dismiss the alert), then show the alert. So, this error will only be shown if something went wrong.
    // This demonstrates one important tip about Swift constants: both errorTitle and errorMessage were declared as constants, which means their value cannot be changed once set. I didn't give either of them an initial value, and that's OK – Swift lets you do this as long as you do provide a value before the constants are read, and also as long as you don't try to change the value again later on.
    
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        
        return true
    }
    // In the isPossible() method we looped over each letter by treating the word as an array, but in this new code we use word.utf16 instead. Why?
    // The answer is an annoying backwards compatibility quirk: Swift’s strings natively store international characters as individual characters, e.g. the letter “é” is stored as precisely that. However, UIKit was written in Objective-C before Swift’s strings came along, and it uses a different character system called UTF-16 – short for 16-bit Unicode Transformation Format – where the accent and the letter are stored separately.
    // It’s a subtle difference, and often it isn’t a difference at all, but it’s becoming increasingly problematic because of the rise of emoji – those little images that are frequently used in messages. Emoji are actually just special character combinations behind the scenes, and they are measured differently with Swift strings and UTF-16 strings: Swift strings count them as 1-letter strings, but UTF-16 considers them to be 2-letter strings. This means if you use count with UIKit methods, you run the risk of miscounting the string length.
    // I realize this seems like pointless additional complexity, so let me try to give you a simple rule: when you’re working with UIKit, SpriteKit, or any other Apple framework, use utf16.count for the character count. If it’s just your own code - i.e. looping over characters and processing each one individually – then use count instead.
    
    
    // There are two new things here. First, contains() is a method that checks whether the array it’s called on (usedWords) contains the value specified in parameter 2 (word). If it does contain the value, contains() returns true; if not, it returns false. Second, the ! symbol. You've seen this before as the way to force unwrap optional variables, but here it's something different: it means not.
    // The difference is small but important: when used before a variable or constant, ! means "not" or "opposite". So if contains() returns true, ! flips it around to make it false, and vice versa. When used after a variable or constant, ! means "force unwrap this optional variable."
    // This is used because our method is called isOriginal(), and should return true if the word has never been used before. If we had used return usedWords.contains(word), then it would do the opposite: it would return true if the word had been used and false otherwise. So, by using ! we're flipping it around so that the method returns true if the word is new.
    func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    // There's a new class here, called UITextChecker. This is an iOS class that is designed to spot spelling errors, which makes it perfect for knowing if a given word is real or not. We're creating a new instance of the class and putting it into the checker constant for later.
    // There's a new type here too, called NSRange. This is used to store a string range, which is a value that holds a start position and a length. We want to examine the whole string, so we use 0 for the start position and the string's length for the length.
    // Next, we call the rangeOfMisspelledWord(in:) method of our UITextChecker instance. This wants five parameters, but we only care about the first two and the last one: the first parameter is our string, word, the second is our range to scan (the whole string), and the last is the language we should be checking with, where en selects English.
    // Parameters three and four aren't useful here, but for the sake of completeness: parameter three selects a point in the range where the text checker should start scanning, and parameter four lets us set whether the UITextChecker should start at the beginning of the range if no misspelled words were found starting from parameter three. Neat, but not helpful here.
    // Calling rangeOfMisspelledWord(in:) returns another NSRange structure, which tells us where the misspelling was found. But what we care about was whether any misspelling was found, and if nothing was found our NSRange will have the special location NSNotFound. Usually location would tell you where the misspelling started, but NSNotFound is telling us the word is spelled correctly – i.e., it's a valid word.
    // Note: In case you were curious, NSRange pre-dates Swift, and therefore doesn’t have access to optionals – NSNotFound is effectively a magic number that means “not found”, assigned to a constant to make it easier to use.
    // Here the return statement is used in a new way: as part of an operation involving ==. This is a very common way to code, and what happens is that == returns true or false depending on whether misspelledRange.location is equal to NSNotFound. That true or false is then given to return as the return value for the method.
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
}

