//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import XCTest
@testable import StyleSyncCore

class StringTests: XCTestCase {
	// MARK: Camelcased
	
	func testCamelcasedStringRemainsTheSame() {
		let originalString = "camelCased"
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
	
	func testTwoCapitalizedWordsSeparatedByASpaceAreCamelcasedCorrectly() {
		let originalString = "Camel Cased"
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
	
	func testTwoLowercasedWordsSeparatedByASpaceAreCamelcasedCorrectly() {
		let originalString = "camel cased"
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
	
	func testTwoUppercasedWordsSeparatedByASpaceAreCamelcasedCorrectly() {
		let originalString = "CAMEL CASED"
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
	
	func testTwoWordsWithASpaceAtTheEndAreCamelcasedCorrectly() {
		let originalString = "camel cased "
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
	
	// MARK: Lowercased with underscore separators
	
	func testLowercasedWithUnderscoreSeparatorsRemainsTheSame() {
		let originalString = "lowercased_underscored"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoCapitalizedWordsSeparatedByASpaceAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "Lowercased Underscored"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoLowercasedWordsSeparatedByASpaceAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "lowercased underscored"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoUppercasedWordsSeparatedByASpaceAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "LOWERCASED UNDERSCORED"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoWordsWithASpaceAtTheEndAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "lowercased underscored "
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoWordsWithAnUnderscoreSurroundedBySpaceAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "lowercased _ underscored"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoWordsWithAnUnderscoreAfterEachWordAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "lowercased_ underscored_"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	// MARK: Capitalized without space separators
	
	func testCapitalizedWithoutSpaceSeparatorsRemainsTheSame() {
		let originalString = "CapitalizedSpace"
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
	
	func testTwoCapitalizedWordsSeparatedByASpaceAreCapitalizedWithoutSpaceSeparatorsCorrectly() {
		let originalString = "Capitalized Space"
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
	
	func testTwoLowercasedWordsSeparatedByASpaceAreCapitalizedWithoutSpaceSeparatorsCorrectly() {
		let originalString = "capitalized space"
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
	
	func testTwoUppercasedWordsSeparatedByASpaceAreCapitalizedWithoutSpaceSeparatorsCorrectly() {
		let originalString = "CAPITALIZED SPACE"
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
	
	func testTwoWordsWithASpaceAtTheEndAreCapitalizedWithoutSpaceSeparatorsCorrectly() {
		let originalString = "capitalized space "
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
	
	// MARK: - Range accounting for surrounding characters
	
	func testStringWithNoSurroundingCharactersIsValid() {
		let string = "abcString"
		let stringToSearchFor = "abcString"
		
		let expectedRange = string.range(of: stringToSearchFor)
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertEqual(range, expectedRange)
	}
	
	func testStringWithAlphanumericCharacterBeforeRangeReturnsNil() {
		let string = "AabcString"
		let stringToSearchFor = "abcString"
		
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertNil(range)
	}
	
	func testStringWithMutlipleAlphanumericCharactersBeforeRangeReturnsNil() {
		let string = "ABabcString"
		let stringToSearchFor = "abcString"
		
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertNil(range)
	}
	
	func testStringWithNonAlphanumericCharacterBeforeRangeIsValid() {
		let string = ".abcString"
		let stringToSearchFor = "abcString"
		
		let expectedRange = string.range(of: stringToSearchFor)
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertEqual(range, expectedRange)
	}
	
	func testStringWithAlphanumericCharacterAfterRangeReturnsNil() {
		let string = "abcStringA"
		let stringToSearchFor = "abcString"
		
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertNil(range)
	}
	
	func testStringWithMutlipleAlphanumericCharactersAfterRangeReturnsNil() {
		let string = "abcStringAB"
		let stringToSearchFor = "abcString"
		
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertNil(range)
	}
	
	func testStringWithNonAlphanumericCharacterAfterRangeIsValid() {
		let string = "abcString)"
		let stringToSearchFor = "abcString"
		
		let expectedRange = string.range(of: stringToSearchFor)
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertEqual(range, expectedRange)
	}
	
	func testStringWithAlphanumericCharactersSurroundingRangeReturnsNil() {
		let string = "0abcString1"
		let stringToSearchFor = "abcString"
		
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertNil(range)
	}
	
	func testStringWithNonAlphanumericCharactersSurroundingRangeIsValid() {
		let string = " abcString "
		let stringToSearchFor = "abcString"
		
		let expectedRange = string.range(of: stringToSearchFor)
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertEqual(range, expectedRange)
	}
	
	func testRangeOfEmptyStringIsNil() {
		let string = "abcString"
		let stringToSearchFor = ""
		
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertNil(range)
	}
	
	func testRangeOfSingleCharacterStringStringIsValid() {
		let string = "a"
		let stringToSearchFor = "a"
		
		let expectedRange = string.range(of: stringToSearchFor)
		let range = string.range(of: stringToSearchFor, whereSurroundingCharactersAreNotContainedIn: .alphanumerics)
		XCTAssertEqual(range, expectedRange)
	}
	
	// MARK: Trailing whitespace
	
	func testTabAtTheEndOfAStringIsRemoved() {
		let string = "a\t"
		let expectedString = "a"
		XCTAssertEqual(string.removingTrailingWhitespace, expectedString)
	}
	
	func testSpaceAtTheEndOfAStringIsRemoved() {
		let string = "a "
		let expectedString = "a"
		XCTAssertEqual(string.removingTrailingWhitespace, expectedString)
	}
	
	func testTabAtTheBeginningOfAStringIsNotRemoved() {
		let string = "\ta"
		let expectedString = "\ta"
		XCTAssertEqual(string.removingTrailingWhitespace, expectedString)
	}
	
	func testSpaceAtTheBeginningOfAStringIsNotRemoved() {
		let string = " a"
		let expectedString = " a"
		XCTAssertEqual(string.removingTrailingWhitespace, expectedString)
	}
	
	func testTabInTheMiddleOfAStringIsNotRemoved() {
		let string = "a\tb"
		let expectedString = "a\tb"
		XCTAssertEqual(string.removingTrailingWhitespace, expectedString)
	}
	
	func testSpaceInTheMiddleOfAStringIsNotRemoved() {
		let string = "a b"
		let expectedString = "a b"
		XCTAssertEqual(string.removingTrailingWhitespace, expectedString)
	}
	
	// MARK: Escape characters
	
	func testEscapedSpaceInStringIsRemoved() {
		let string = "a\\ b"
		let expectedString = "a b"
		XCTAssertEqual(string.removingEscapeCharacters, expectedString)
	}
	
	func testEscapedEscapeCharacterInStringIsRemoved() {
		let string = "a\\\\b"
		let expectedString = "a\\b"
		XCTAssertEqual(string.removingEscapeCharacters, expectedString)
	}
	
	func testEmojiInStringIsNotRemoved() {
		let string = "a💖b"
		let expectedString = "a💖b"
		XCTAssertEqual(string.removingEscapeCharacters, expectedString)
	}
}
