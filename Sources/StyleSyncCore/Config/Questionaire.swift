//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation
import Files

struct Questionaire {
	private var creatable: Creatable
	private var didFinishQuestionaire: (Creatable) -> Void
	
	init(creatable: Creatable, didFinishQuestionaire: @escaping (Creatable) -> Void) {
		self.creatable = creatable
		self.didFinishQuestionaire = didFinishQuestionaire
	}
	
	func startQuestionaire() {
		var creatable: Creatable = self.creatable
		var nextQuestion: Question? = creatable.firstQuestion
		repeat {
			guard let question = nextQuestion else {
				return
			}
			print("\n" + question.question)
			let answer = readLine() ?? ""
			let cleanedAnswer = answer.removingEscapeCharacters.removingTrailingWhitespace
			if let (newCreatable, newNextQuestion) = question.didAnswerQuestion(creatable, cleanedAnswer) {
				if let newCreatable = newCreatable {
					creatable = newCreatable
				}
				nextQuestion = newNextQuestion
			}
		} while nextQuestion != nil
		didFinishQuestionaire(creatable)
	}
}

struct Question {
	typealias DidAnswerQuestion = (Creatable, String) -> (Creatable?, Question?)?
	
	var question: String
	var didAnswerQuestion: DidAnswerQuestion
	
	init(question: String, didAnswerQuestion: @escaping DidAnswerQuestion) {
		self.question = question
		self.didAnswerQuestion = didAnswerQuestion
	}
}

protocol Creatable: Codable {
	var firstQuestion: Question { get }
}
