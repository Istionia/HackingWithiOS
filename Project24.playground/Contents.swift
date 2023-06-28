import UIKit

var greeting = "Hello, playground"

let name = "Taylor"

for letter in name {
    print("Give me a \(letter)!")
}

let letter = name[name.index(name.startIndex, offsetBy: 3)]

extension String {
    subscript(i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
}

let password = "12345"
password.hasPrefix("123")
password.hasSuffix("345")

extension String {
    // remove a prefix if it exists
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    // remove a suffix if it exists
    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
}

let weather = "it's going to rain"
print(weather.capitalized)

extension String {
    var capitalizedFirst: String {
        guard let firstLetter = self.first else { return "" }
        return firstLetter.uppercased() + self.dropFirst()
    }
}

let input = "Swift is like Objective-C without the C"
input.contains("Swift")

let languages = ["Python", "Ruby", "Swift"]
languages.contains("Swift")

extension String {
    func containsAny(of array: [String]) -> Bool {
        for item in array {
            if self.contains(item) {
                return true
            }
        }

        return false
    }
}

input.containsAny(of: languages)

// contains(where:) will call its closure once for every element in the languages array until it finds one that returns true, at which point it stops.
// In that code we’re passing input.contains as the closure that contains(where:) should run. This means Swift will call input.contains("Python") and get back false, then it will call input.contains("Ruby") and get back false again, and finally call input.contains("Swift") and get back true – then stop there.
// So, because the contains() method of strings has the exact same signature that contains(where:) expects (take a string and return a Boolean), this works perfectly.
languages.contains(where: input.contains)
// It’s common to use an explicit type annotation when making attributed strings, because inside the dictionary we can just write things like .foregroundColor for the key rather than NSAttributedString.Key.foregroundColor.
// The values of the attributes dictionary are of type Any, because NSAttributedString attributes can be all sorts of things: numbers, colors, fonts, paragraph styles, and more.
// If you look in the output pane of your playground, you should be able to click on the box next to where it says “This is a test string” to get a live preview of how our string looks – you should see large, white text with a red background.
let string = "This is a test string"
let attributes: [NSAttributedString.Key: Any] = [
    .foregroundColor: UIColor.white,
    .backgroundColor: UIColor.red,
    .font: UIFont.boldSystemFont(ofSize: 36)
]

// Of course, we could get the same effect with a regular string placed inside a UILabel: change the font and colors, and it would look the same. But what labels can’t do is add formatting to different parts of the string.
// To demonstrate this we’re going to use NSMutableAttributedString, which is an attributed string that you can modify:
let attributedString = NSMutableAttributedString(string: string)
attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 8), range: NSRange(location: 0, length: 4))
attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 5, length: 2))
attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 24), range: NSRange(location: 8, length: 1))
attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 32), range: NSRange(location: 10, length: 4))
attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 40), range: NSRange(location: 15, length: 6))
//When you preview that you’ll see the font size get larger with each word – something a regular Swift string certainly can’t do even with help from UILabel.
// There are lots of formatting options for attributed strings, including:
    // Set .underlineStyle to a value from NSUnderlineStyle to strike out characters.
    // Set .strikethroughStyle to a value from NSUnderlineStyle (no, that’s not a typo) to strike out characters.
    // Set .paragraphStyle to an instance of NSMutableParagraphStyle to control text alignment and spacing.
    // Set .link to be a URL to make clickable links in your strings.
// And that’s just a subset of what you can do.
// You might be wondering how useful all this knowledge is, but here’s the important part: UILabel, UITextField, UITextView, UIButton, UINavigationBar, and more all support attributed strings just as well as regular strings. So, for a label you would just use attributedText rather than text, and UIKit takes care of the rest.

extension String {
    // Create a String extension that adds a withPrefix() method. If the string already contains the prefix it should return itself; if it doesn’t contain the prefix, it should return itself with the prefix added. For example: "pet".withPrefix("car") should return “carpet”.
    func addPrefix(_ prefix: String) -> String {
        if string.hasPrefix(prefix) {
            return self
        } else {
            return self.addPrefix(prefix)
        }
    }
}

var isNumeric = false

extension String {
   // Create a String extension that adds an isNumeric property that returns true if the string holds any sort of number.
}
