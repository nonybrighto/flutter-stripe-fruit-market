//
//  PhoneNumberElement.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 9/22/21.
//

import UIKit

@_spi(STP) import StripeCore

@_spi(STP) public class PhoneNumberElement: Element {
    
    public lazy var view: UIView = {
        let elementView = PhoneNumberFieldView(
            regionDropDown: regionElement.view,
            regionPrefixLabel: regionPrefixLabel,
            numberTextView: numberElement.textFieldView.textField
        )
        let floatingPlaceholderView = FloatingPlaceholderView(contentView: elementView)
        floatingPlaceholderView.placeholder = STPLocalizedString("Mobile number", "Form field header for entering a mobile phone number")
        let view = UIView()
        view.addAndPinSubview(floatingPlaceholderView, insets: ElementsUI.contentViewInsets)
        return view
    }()
    
    public var delegate: ElementDelegate? = nil
    
    private(set) lazy var regionElement: DropdownFieldElement = {
        let element = DropdownFieldElement(
            items: sortedPickerValues,
            defaultIndex: selectedRegionIndex,
            label: nil,
            didUpdate: { [weak self] index in
                guard let self = self else {
                    return
                }

                self.selectedRegionIndex = index
                self.delegate?.didUpdate(element: self)
            }
        )
        element.delegate = self
        return element
    }()
    
    private lazy var numberElement: TextFieldElement = {
        let numberElement = TextFieldElement(
            configuration: TextFieldElement.Address.PhoneNumberConfiguration(regionCode: sortedRegionInfo[selectedRegionIndex].regionCode)
        )
        numberElement.delegate = self
        return numberElement
    }()

    private let locale: Locale

    private var selectedRegionIndex: Int = 0 {
        didSet {
            updateUI()
        }
    }
    
    public var phoneNumber: PhoneNumber? {
        return PhoneNumber(number: numberElement.text, countryCode: selectedRegionCode)
    }
    
    public func resetNumber() {
        numberElement.setText("")
    }
    
    /// Phone number text formatted as E164 or unformatted if unknown region
    public var phoneNumberText: String? {
        if let phoneNumber = phoneNumber {
            let e164Formatted =  phoneNumber.string(as: .e164)
            if e164Formatted == phoneNumber.prefix || e164Formatted.isEmpty {
                return nil // user hasn't entered anything
            } else {
                return phoneNumber.string(as: .e164)
            }
        } else if case .valid = numberElement.validationState {
            return numberElement.text
        }
        return nil
    }

    public init(
        defaultValue: String? = nil,
        defaultCountry: String? = nil,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.locale = locale
        self.selectedRegionIndex = sortedRegionInfo.firstIndex { regionInfo in
            regionInfo.regionCode == (defaultCountry ?? locale.regionCode)
        } ?? 0

        guard let defaultValue = defaultValue else {
            return
        }

        if let phoneNumber = PhoneNumber.fromE164(defaultValue, locale: locale),
           let index = sortedRegionInfo.firstIndex(where: { phoneNumber.countryCode == $0.regionCode }) {
            selectedRegionIndex = index
            numberElement.setText(phoneNumber.number)
        } else {
            numberElement.setText(defaultValue)
        }
    }
    
    var selectedRegionCode: String? {
        return sortedRegionInfo[selectedRegionIndex].regionCode
    }
    
    var selectedMetadata: PhoneNumber.Metadata? {
        return sortedRegionInfo[selectedRegionIndex].metadata
    }
    
    private lazy var regionPrefixLabel: UILabel = {
        let label = UILabel()
        label.font = ElementsUITheme.current.fonts.subheadline
        label.textColor = ElementsUITheme.current.colors.placeholderText
        label.text = selectedMetadata?.prefix
        return label
    }()
    
    // MARK: - Sorted Picker Values
    private(set) lazy var sortedRegionInfo: [RegionInfo] = {
        
        var allRegionInfo: [RegionInfo] = locale.sortedByTheirLocalizedNames(PhoneNumber.Metadata.allMetadata).map { metadata in
            let regionCode = metadata.regionCode
            let flagEmoji = String.countryFlagEmoji(for: regionCode)
            
            let identifier = Locale.identifier(fromComponents: [
                NSLocale.Key.countryCode.rawValue: regionCode
            ])
            let name: String = locale.localizedString(forRegionCode: regionCode) ?? regionCode
                        
            return RegionInfo(flagEmoji: flagEmoji, name: name, labelName: flagEmoji ?? regionCode, metadata: metadata)
        }

        allRegionInfo.append(RegionInfo(flagEmoji: "🌐", name: String.Localized.other, labelName: "🌐", metadata: nil))
        
        return allRegionInfo
    }()
    
    private lazy var sortedPickerValues: [DropdownFieldElement.DropdownItem] = {
                
        return sortedRegionInfo.map { regionInfo in
            let pickerDisplayName: String = {
                if let flagEmoji = regionInfo.flagEmoji {
                    return [flagEmoji, regionInfo.name].joined(separator: " ")
                } else {
                    return regionInfo.name
                }
            }()
            return DropdownFieldElement.DropdownItem(pickerDisplayName: pickerDisplayName,
                                                     labelDisplayName: regionInfo.labelName,
                                                     accessibilityLabel: regionInfo.name)
        }
    }()

    private func updateUI() {
        regionPrefixLabel.text = selectedMetadata?.prefix
        numberElement.configuration = TextFieldElement.Address.PhoneNumberConfiguration(
            regionCode: selectedRegionCode
        )
    }
}

// MARK: - ElementDelegate
/// :nodoc:
extension PhoneNumberElement: ElementDelegate {
    public func didUpdate(element: Element) {
        delegate?.didUpdate(element: self)
    }
    
    public func continueToNextField(element: Element) {
        if element as? DropdownFieldElement == regionElement {
            _ = numberElement.beginEditing()
        } else {
            delegate?.continueToNextField(element: self)
        }
    }
    
    
}

// MARK: - Data Helpers
/// :nodoc:
extension PhoneNumberElement {
    struct RegionInfo {
        let flagEmoji: String?
        let name: String
        let labelName: String
        let metadata: PhoneNumber.Metadata?
        
        var regionCode: String? {
            return metadata?.regionCode
        }
    }
}

