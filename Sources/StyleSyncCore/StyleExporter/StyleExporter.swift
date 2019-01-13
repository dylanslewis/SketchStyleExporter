//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation
import Files

final class StyleExporter {
	// MARK: - Constants
	
	private enum Constant {
		static let defaultColorStylesName = "ColorStyles"
		static let defaultTextStylesName = "TextStyles"
	}
	
	// MARK: - Stored variables
	
	private let latestTextStyles: [TextStyle]
	private let latestColorStyles: [ColorStyle]
	private let previouslyExportedTextStyles: [TextStyle]
	private let previouslyExportedColorStyles: [ColorStyle]
	
	var oldTextStyles: [CodeTemplateReplacableStyle] = []
	var oldColorStyles: [CodeTemplateReplacableStyle] = []
	var newTextStyles: [CodeTemplateReplacableStyle] = []
	var newColorStyles: [CodeTemplateReplacableStyle] = []
	
	private let projectFolder: Folder
	private let textStyleTemplateFile: File
	private let colorStyleTemplateFile: File
	private let exportTextFolder: Folder
	private let exportColorsFolder: Folder
	private let generatedRawTextStylesFile: File
	private let generatedRawColorStylesFile: File
	
	private var filesForDeprecatedColorStyle: [CodeTemplateReplacableStyle: [File]] = [:]
	private var filesForDeprecatedTextStyle: [CodeTemplateReplacableStyle: [File]] = [:]
	
	var generatedTextStylesFile: File!
	var generatedColorStylesFile: File!
	
	private let previousStylesVersion: Version?
	var version: Version!
	
	// MARK: - Computed variables
	
	private var usedDeprecatedColorStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedColorStyle.keys)
	}
	private var usedDeprecatedTextStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedTextStyle.keys)
	}
	
	private(set) var mutatedFiles: Set<File> = []
	var fileNamesForDeprecatedStyleNames: [String: [String]] {
		var fileNamesForDeprecatedStyleNames: [String: [String]] = [:]
		Array(filesForDeprecatedColorStyle.keys)
			.forEach { style in
				let filesForStyle = filesForDeprecatedColorStyle[style]
				let fileNames: [String] = filesForStyle?.map({ $0.name }) ?? []
				fileNamesForDeprecatedStyleNames[style.name] = fileNames
		}
		Array(filesForDeprecatedTextStyle.keys)
			.forEach { style in
				let filesForStyle = filesForDeprecatedTextStyle[style]
				let fileNames: [String] = filesForStyle?.map({ $0.name }) ?? []
				fileNamesForDeprecatedStyleNames[style.name] = fileNames
		}
		return fileNamesForDeprecatedStyleNames
	}
	
	// MARK: - Initializer
	
	init(
		latestTextStyles: [TextStyle],
		latestColorStyles: [ColorStyle],
		previouslyExportedTextStyles: [TextStyle],
		previouslyExportedColorStyles: [ColorStyle],
		projectFolder: Folder,
		textStyleTemplateFile: File,
		colorStyleTemplateFile: File,
		exportTextFolder: Folder,
		exportColorsFolder: Folder,
		generatedRawTextStylesFile: File,
		generatedRawColorStylesFile: File,
		previousStylesVersion: Version?
	) {
		self.latestTextStyles = latestTextStyles
		self.latestColorStyles = latestColorStyles
		self.previouslyExportedTextStyles = previouslyExportedTextStyles
		self.previouslyExportedColorStyles = previouslyExportedColorStyles
		self.projectFolder = projectFolder
		self.textStyleTemplateFile = textStyleTemplateFile
		self.colorStyleTemplateFile = colorStyleTemplateFile
		self.exportTextFolder = exportTextFolder
		self.exportColorsFolder = exportColorsFolder
		self.generatedRawTextStylesFile = generatedRawTextStylesFile
		self.generatedRawColorStylesFile = generatedRawColorStylesFile
		self.previousStylesVersion = previousStylesVersion
	}
	
	// MARK: - Actions
	
	func exportStyles() throws {
		let (textStyleParser, colorStyleParser) = createStyleParsers(
			latestTextStyles: latestTextStyles,
			latestColorStyles: latestColorStyles
		)
		
		let currentAndMigratedTextStyles = textStyleParser
			.getCurrentAndMigratedStyles(usingPreviouslyExportedStyles: previouslyExportedTextStyles)
		let currentAndMigratedColorStyles = colorStyleParser
			.getCurrentAndMigratedStyles(usingPreviouslyExportedStyles: previouslyExportedColorStyles)
		let deprecatedTextStyles = textStyleParser
			.deprecatedStyles(usingPreviouslyExportedStyles: previouslyExportedTextStyles)
		let deprecatedColorStyles = colorStyleParser
			.deprecatedStyles(usingPreviouslyExportedStyles: previouslyExportedColorStyles)
		
		let (textStyleCodeGenerator, colorStyleCodeGenerator) = try createStyleCodeGenerators(
			textStyleTemplateFile: textStyleTemplateFile,
			colorStyleTemplateFile: colorStyleTemplateFile
		)
		
		let textStylesFileExtension = textStyleCodeGenerator.fileExtension
		let colorStylesFileExtension = colorStyleCodeGenerator.fileExtension
		
		generatedTextStylesFile = try exportTextFolder.createFileIfNeeded(
			named: textStyleCodeGenerator.fileName ?? Constant.defaultTextStylesName,
			fileExtension: textStylesFileExtension
		)
		generatedColorStylesFile = try exportColorsFolder.createFileIfNeeded(
			named: colorStyleCodeGenerator.fileName ?? Constant.defaultColorStylesName,
			fileExtension: colorStylesFileExtension
		)
		
		(newColorStyles, newTextStyles) = processStyles(
			deprecatedTextStyles: deprecatedTextStyles,
			deprecatedColorStyles: deprecatedColorStyles,
			latestTextStyles: latestTextStyles,
			latestColorStyles: latestColorStyles,
			textStylesFileExtension: textStylesFileExtension,
			colorStylesFileExtension: colorStylesFileExtension
		)
		
		print("Updating references to styles in your project")
		let ignoredFiles: [File] = [
			generatedColorStylesFile,
			generatedTextStylesFile
		]
		
		try updateFilesInProjectDirectoryAndFindUsedDeprecatedStyles(
			textStylesFileExtension: textStylesFileExtension,
			colorStylesFileExtension: colorStylesFileExtension,
			currentAndMigratedTextStyles: currentAndMigratedTextStyles,
			currentAndMigratedColorStyles: currentAndMigratedColorStyles,
			deprecatedTextStyles: deprecatedTextStyles,
			deprecatedColorStyles: deprecatedColorStyles,
			ignoredFiles: ignoredFiles
		)
		
		newTextStyles = newTextStyles + usedDeprecatedTextStyles
		newColorStyles = newColorStyles + usedDeprecatedColorStyles
		
		oldColorStyles = previouslyExportedColorStyles.map({
			CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStyleCodeGenerator.fileExtension)
		})
		oldTextStyles = previouslyExportedTextStyles.map({
			CodeTemplateReplacableStyle(textStyle: $0, fileType: textStyleCodeGenerator.fileExtension)
		})
		
		updateVersion()
		
		print("Generating styling code")
		try generateAndSaveStyleCode(
			version: version,
			colorStyles: newColorStyles,
			textStyles: newTextStyles,
			textStylesCodeGenerator: textStyleCodeGenerator,
			colorStylesCodeGenerator: colorStyleCodeGenerator
		)
		try generateAndSaveVersionedStyles(
			version: version,
			colorStyles: newColorStyles.map({ $0.style as? ColorStyle }).compactMap({$0}),
			textStyles: newTextStyles.map({ $0.style as? TextStyle }).compactMap({$0}),
			generatedRawTextStylesFile: generatedRawTextStylesFile,
			generatedRawColorStylesFile: generatedRawColorStylesFile
		)
		
		printUpdatedStyles()
		print("🎉  Successfully generated style files at:\n\(generatedTextStylesFile.path)\n\(generatedColorStylesFile.path)")
	}
	
	private func createStyleParsers(latestTextStyles: [TextStyle], latestColorStyles: [ColorStyle]) -> (text: StyleParser<TextStyle>, color: StyleParser<ColorStyle>) {
		let textStyleParser = StyleParser(newStyles: latestTextStyles)
		let colorStyleParser = StyleParser(newStyles: latestColorStyles)
		return (textStyleParser, colorStyleParser)
	}
	
	/// Removes unused deprecated styles from project files and creates two
	/// arrays of styles ready to be exported.
	///
	/// - Parameters:
	///   - deprecatedTextStyles: Deprecated text styles
	///   - deprecatedColorStyles: Deprecated color styles
	///   - latestTextStyles: The Sketch file's text styles
	///   - latestColorStyles: The Sketch file's color styles
	///   - textStylesFileExtension: The text style's export file extension
	///   - colorStylesFileExtension: The color style's export file extension
	private func processStyles(
		deprecatedTextStyles: [TextStyle],
		deprecatedColorStyles: [ColorStyle],
		latestTextStyles: [TextStyle],
		latestColorStyles: [ColorStyle],
		textStylesFileExtension: String,
		colorStylesFileExtension: String
	) -> (colorStyles: [CodeTemplateReplacableStyle], textStyles: [CodeTemplateReplacableStyle]) {
		var deprecatedReplacableTextStyles = deprecatedTextStyles
			.map({ CodeTemplateReplacableStyle(textStyle: $0, fileType: textStylesFileExtension) })
		var deprecatedReplacableColorStyles = deprecatedColorStyles
			.map({ CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStylesFileExtension) })
		let latestReplacableTextStyles = latestTextStyles
			.map({ CodeTemplateReplacableStyle(textStyle: $0, fileType: textStylesFileExtension) })
		let latestReplacableColorStyles = latestColorStyles
			.map({ CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStylesFileExtension) })
		
		removeUnusedDeprecatedStyles(
			deprecatedStyles: &deprecatedReplacableColorStyles,
			usedDeprecatedStyles: usedDeprecatedColorStyles,
			newStyles: latestReplacableColorStyles
		)
		removeUnusedDeprecatedStyles(
			deprecatedStyles: &deprecatedReplacableTextStyles,
			usedDeprecatedStyles: usedDeprecatedTextStyles,
			newStyles: latestReplacableTextStyles
		)
		
		let allColorStyles = latestReplacableColorStyles + deprecatedReplacableColorStyles
		let allTextStyles = latestReplacableTextStyles + deprecatedReplacableTextStyles
		
		return (allColorStyles, allTextStyles)
	}
	
	private func createStyleCodeGenerators(
		textStyleTemplateFile: File,
		colorStyleTemplateFile: File
	) throws -> (text: CodeGenerator, color: CodeGenerator) {
		let textStyleCodeGenerator = try CodeGenerator(templateFile: textStyleTemplateFile)
		let colorStyleCodeGenerator = try CodeGenerator(templateFile: colorStyleTemplateFile)
		return (textStyleCodeGenerator, colorStyleCodeGenerator)
	}
	
	private func updateFilesInProjectDirectoryAndFindUsedDeprecatedStyles(
		textStylesFileExtension: String,
		colorStylesFileExtension: String,
		currentAndMigratedTextStyles: [(TextStyle, TextStyle)],
		currentAndMigratedColorStyles: [(ColorStyle, ColorStyle)],
		deprecatedTextStyles: [TextStyle],
		deprecatedColorStyles: [ColorStyle],
		ignoredFiles: [File]
	) throws {
		// Create references pairs of the current style's name and its
		// identifier. This prevents an issue where a style that is renamed to
		// an existing style's name may not be updated correctly.
		let textStyleToIdentifierReference = currentAndMigratedTextStyles
			.map({ $0.0 })
			.map({ ReplaceableReference.referenceToIdentifier(from: $0, fileType: textStylesFileExtension) })
		let colorStyleToIdentifierReference = currentAndMigratedColorStyles
			.map({ $0.0 })
			.map({ ReplaceableReference.referenceToIdentifier(from: $0, fileType: colorStylesFileExtension) })

		let updateTextStylesToIdentifiersOperation = updateReferencesFileOperation(
			currentAndMigratedReferences: textStyleToIdentifierReference,
			mutatedFiles: &mutatedFiles
		)
		let updateColorStylesToIdentifiersOperation = updateReferencesFileOperation(
			currentAndMigratedReferences: colorStyleToIdentifierReference,
			mutatedFiles: &mutatedFiles
		)
		
		// Create reference pairs of the identifier and the migrated style's
		// name.
		let identifierToTextStyleReference = currentAndMigratedTextStyles
			.map({ $0.1 })
			.map({ ReplaceableReference.referenceFromIdentifier(to: $0, fileType: textStylesFileExtension) })
		let identifierToColorStyleReference = currentAndMigratedColorStyles
			.map({ $0.1 })
			.map({ ReplaceableReference.referenceFromIdentifier(to: $0, fileType: colorStylesFileExtension) })
		
		let updateIdentifiersToMigratedTextStylesOperation = updateReferencesFileOperation(
			currentAndMigratedReferences: identifierToTextStyleReference,
			mutatedFiles: &mutatedFiles
		)
		let updateIdentifiersToMigratedColorStylesOperation = updateReferencesFileOperation(
			currentAndMigratedReferences: identifierToColorStyleReference,
			mutatedFiles: &mutatedFiles
		)
		
		// Find used deprecated styles.
		let deprecatedTextStyles = deprecatedTextStyles
			.map({ CodeTemplateReplacableStyle(textStyle: $0, fileType: textStylesFileExtension) })
		let deprecatedColorStyles = deprecatedColorStyles
			.map({ CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStylesFileExtension) })
		
		let findUsedDeprecatedColorStylesOperation = findUsedDeprecatedStylesFileOperation(
			deprecatedStyles: deprecatedColorStyles,
			filesForDeprecatedStyle: &filesForDeprecatedColorStyle
		)
		let findUsedDeprecatedTextStylesOperation = findUsedDeprecatedStylesFileOperation(
			deprecatedStyles: deprecatedTextStyles,
			filesForDeprecatedStyle: &filesForDeprecatedTextStyle
		)
		
		// All conversions to identifiers must happen before any references are
		// updates to their migrated name.
		let preparationOperations: [FileOperation] = [
			updateTextStylesToIdentifiersOperation,
			updateColorStylesToIdentifiersOperation
		]
		
		let allOperations: [FileOperation] = [
			updateIdentifiersToMigratedTextStylesOperation,
			updateIdentifiersToMigratedColorStylesOperation,
			findUsedDeprecatedColorStylesOperation,
			findUsedDeprecatedTextStylesOperation
		]
		
		let files = projectFolder
			.makeFileSequence(recursive: true, includeHidden: false)
			.filter({ file -> Bool in
				// Only update files that are encoded as `String`.
				do {
					_ = try file.readAsString()
				} catch {
					return false
				}
				return true
			})
			.filter({ !ignoredFiles.contains($0) })
		
		files.forEach({ file in
			preparationOperations.forEach({ $0(file) })
		})
		files.forEach({ file in
			allOperations.forEach({ $0(file) })
		})
	}
	
	private func updateVersion() {
		version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: newColorStyles,
			newTextStyles: newTextStyles,
			previousStylesVersion: previousStylesVersion
		)
	}
	
	private func generateAndSaveStyleCode(
		version: Version,
		colorStyles: [CodeTemplateReplacableStyle],
		textStyles: [CodeTemplateReplacableStyle],
		textStylesCodeGenerator: CodeGenerator,
		colorStylesCodeGenerator: CodeGenerator
	) throws {
		let generatedTextStylesCode = textStylesCodeGenerator
			.generatedCode(for: [textStyles], version: version)
		let generatedColorStylesCode = colorStylesCodeGenerator
			.generatedCode(for: [colorStyles], version: version)
		
		try generatedColorStylesFile.write(string: generatedColorStylesCode)
		try generatedTextStylesFile.write(string: generatedTextStylesCode)
	}
	
	private func generateAndSaveVersionedStyles(
		version: Version,
		colorStyles: [ColorStyle],
		textStyles: [TextStyle],
		generatedRawTextStylesFile: File,
		generatedRawColorStylesFile: File
	) throws {
		let versionedTextStyles = VersionedStyle.Text(version: version, textStyles: textStyles)
		let versionedColorStyles = VersionedStyle.Color(version: version, colorStyles: colorStyles)
		
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let rawTextStylesData = try encoder.encode(versionedTextStyles)
		let rawColorStylesData = try encoder.encode(versionedColorStyles)
		
		try generatedRawTextStylesFile.write(data: rawTextStylesData)
		try generatedRawColorStylesFile.write(data: rawColorStylesData)
	}
	
	private func printUpdatedStyles() {
		let consoleLogGenerator: StyleUpdateSummaryGenerator
		do {
			consoleLogGenerator = try StyleUpdateSummaryGenerator(
				headingTemplate: ConsoleTemplate.heading,
				styleNameTemplate: ConsoleTemplate.styleName,
				addedStyleTableTemplate: ConsoleTemplate.newStyleTable,
				updatedStyleTableTemplate: ConsoleTemplate.updatedStylesTable,
				deprecatedStylesTableTemplate: ConsoleTemplate.deprecatedStylesTable,
				fileExtension: .log,
				shouldPrintStyleSyncLink: false
			)
		} catch {
			ErrorManager.log(error: error, context: .printStyles)
			return
		}

		let consoleLog = consoleLogGenerator.body(
			fromOldColorStyles: oldColorStyles,
			newColorStyles: newColorStyles,
			oldTextStyles: oldTextStyles,
			newTextStyles: newTextStyles,
			fileNamesForDeprecatedStyleNames: fileNamesForDeprecatedStyleNames
		)
		print(consoleLog)
	}
	
	// MARK: - Helpers
	
	private func updateReferencesFileOperation(
		currentAndMigratedReferences: [ReplaceableReference],
		mutatedFiles: inout Set<File>
	) -> FileOperation {
		return { file in
			var fileString: String
			do {
				fileString = try file.readAsString()
			} catch {
				ErrorManager.log(error: error, context: .files)
				return
			}
			currentAndMigratedReferences.forEach({
				var containsOccurence = true
				repeat {
					guard let range = fileString.range(of: $0.fromReference, whereSurroundingCharactersAreNotContainedIn: .alphanumerics) else {
						containsOccurence = false
						return
					}
					fileString = fileString.replacingCharacters(in: range, with: $0.toReference)
					mutatedFiles.insert(file)
				} while containsOccurence == true
			})
			
			do {
				try file.write(string: fileString)
			} catch {
				ErrorManager.log(error: error, context: .files)
			}
		}
	}
	
	private func findUsedDeprecatedStylesFileOperation(
		deprecatedStyles: [CodeTemplateReplacableStyle],
		filesForDeprecatedStyle: inout [CodeTemplateReplacableStyle: [File]]
	) -> FileOperation {
		return { file in
			var fileString: String
			do {
				fileString = try file.readAsString()
			} catch {
				ErrorManager.log(error: error, context: .files)
				return
			}
			
			deprecatedStyles
				.filter({ fileString.contains($0.variableName) })
				.forEach({ style in
					var filesForStyle = filesForDeprecatedStyle[style] ?? []
					guard !filesForStyle.contains(file) else {
						return
					}
					filesForStyle.append(file)
					filesForDeprecatedStyle[style] = filesForStyle
				})
		}
	}
	
	private func removeUnusedDeprecatedStyles(
		deprecatedStyles: inout [CodeTemplateReplacableStyle],
		usedDeprecatedStyles: [CodeTemplateReplacableStyle],
		newStyles: [CodeTemplateReplacableStyle]
	) {
		// Only styles that are still in the project should be deprecated, and
		// any others removed completely.
		deprecatedStyles = deprecatedStyles
			.filter({ return usedDeprecatedStyles.contains($0) })
			.filter({ style -> Bool in
				// If a style is removed but another is added with the same
				// name, then remove the deprecated one to avoid compilation
				// issues.
				if newStyles.contains(where: { return $0.variableName == style.variableName }) {
					ErrorManager.log(warning: "Style with name \(style.variableName) was removed and added again with a different name.")
					return false
				} else {
					return true
				}
			})
	}
}
