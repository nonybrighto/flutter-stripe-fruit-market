//
//  TextFieldElement.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

/**
 A generic text field whose logic is extracted into `TextFieldElementConfiguration`.
 
 - Seealso: `TextFieldElementConfiguration`
 */
@_spi(STP) public final class TextFieldElement {
    
    // MARK: - Properties
    weak public var delegate: ElementDelegate?
    public var isOptional: Bool = false {
        didSet {
            textFieldView.updateUI(with: viewModel)
            delegate?.didUpdate(element: self)
        }
    }
    
    lazy var textFieldView: TextFieldView = {
        return TextFieldView(viewModel: viewModel, delegate: self)
    }()
    var configuration: TextFieldElementConfiguration {
        didSet {
            setText("")
        }
    }
    public private(set) lazy var text: String = {
        sanitize(text: configuration.defaultValue ?? "")
    }()
    var isEditing: Bool = false
    public var validationState: ValidationState {
        return configuration.validate(text: text, isOptional: isOptional)
    }
    
    // MARK: - ViewModel
    public struct KeyboardProperties {
        public init(type: UIKeyboardType, textContentType: UITextContentType?, autocapitalization: UITextAutocapitalizationType) {
            self.type = type
            self.textContentType = textContentType
            self.autocapitalization = autocapitalization
        }
        
        let type: UIKeyboardType
        let textContentType: UITextContentType?
        let autocapitalization: UITextAutocapitalizationType
    }

    struct ViewModel {
        let floatingPlaceholder: String?
        let staticPlaceholder: String? // optional placeholder that does not float/stays in the underlying text field
        let accessibilityLabel: String
        let attributedText: NSAttributedString
        let keyboardProperties: KeyboardProperties
        let validationState: ValidationState
        let logo: (lightMode: UIImage, darkMode: UIImage)?
    }
    
    var viewModel: ViewModel {
        let placeholder: String = {
            if !isOptional {
                return configuration.label
            } else {
                let localized = String.Localized.optional_field
                return String(format: localized, configuration.label)
            }
        }()
        return ViewModel(
            floatingPlaceholder: configuration.placeholderShouldFloat ? placeholder : nil,
            staticPlaceholder: configuration.placeholderShouldFloat ? nil : placeholder,
            accessibilityLabel: configuration.accessibilityLabel,
            attributedText: configuration.makeDisplayText(for: text),
            keyboardProperties: configuration.keyboardProperties(for: text),
            validationState: validationState,
            logo: configuration.logo(for: text)
        )
    }

    // MARK: - Initializer
    
    public required init(configuration: TextFieldElementConfiguration) {
        self.configuration = configuration
    }
    
    /// Call this to manually set the text of the text field.
    public func setText(_ text: String) {
        self.text = sanitize(text: text)
        
        // Glue: Update the view and our delegate
        textFieldView.updateUI(with: viewModel)
        delegate?.didUpdate(element: self)
    }

    // MARK: - Helpers
    
    func sanitize(text: String) -> String {
        let sanitizedText = text.stp_stringByRemovingCharacters(from: configuration.disallowedCharacters)
        return String(sanitizedText.prefix(configuration.maxLength(for: sanitizedText)))
    }
}

// MARK: - Element

extension TextFieldElement: Element {
    public var view: UIView {
        return textFieldView
    }
    
    public func beginEditing() -> Bool {
        return textFieldView.textField.becomeFirstResponder()
    }
    
    public var errorText: String? {
        guard
            case .invalid(let error) = validationState,
            error.shouldDisplay(isUserEditing: isEditing)
        else {
            return nil
        }
        return error.localizedDescription
    }

    public var subLabelText: String? {
        return configuration.subLabel(text: text)
    }
}

// MARK: - TextFieldViewDelegate

extension TextFieldElement: TextFieldViewDelegate {
    func textFieldViewDidUpdate(view: TextFieldView) {
        // Update our state
        let newText = sanitize(text: view.text)
        if text != newText {
            text = newText
            // Advance to the next field if text is maximum length and valid
            if text.count == configuration.maxLength(for: text), case .valid = validationState {
                view.endEditing(true)
                delegate?.continueToNextField(element: self)
            }
        }
        isEditing = view.isEditing
        
        // Glue: Update the view and our delegate
        view.updateUI(with: viewModel)
        delegate?.didUpdate(element: self)
    }
    
    func textFieldViewContinueToNextField(view: TextFieldView) {
        isEditing = view.isEditing
        delegate?.continueToNextField(element: self)
    }
}
