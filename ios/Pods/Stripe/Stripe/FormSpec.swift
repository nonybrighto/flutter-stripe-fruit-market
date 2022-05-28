//
//  FormSpec.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

/// A decodable representation that can used to construct a `FormElement`
struct FormSpec: Decodable {
    let type: String
    let async: Bool?
    let fields: [FieldSpec]

    enum FieldSpec: Decodable, Equatable {
        case name(NameFieldSpec)
        case email(BaseFieldSpec)
        case selector(SelectorSpec)
        case billing_address

        case affirm_header

        case klarna_header
        case klarna_country(BaseFieldSpec)

        case au_becs_bsb_number(BaseFieldSpec)
        case au_becs_account_number(BaseFieldSpec)
        case au_becs_mandate

        case afterpay_header

        case sofort_billing_address(SofortBillingAddress)

        case iban(BaseFieldSpec)
        case sepa_mandate

        private enum CodingKeys: String, CodingKey {
            case type
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let field_type = try container.decode(String.self, forKey: .type)

            switch(field_type) {
            case "name":
                self = .name(try NameFieldSpec(from: decoder))
            case "email":
                self = .email(try BaseFieldSpec(from: decoder))
            case "selector":
                self = .selector(try SelectorSpec(from: decoder))
            case "billing_address":
                self = .billing_address
            case "affirm_header":
                self = .affirm_header
            case "klarna_header":
                self = .klarna_header
            case "klarna_country":
                self = .klarna_country(try BaseFieldSpec(from: decoder))
            case "au_becs_bsb_number":
                self = .au_becs_bsb_number(try BaseFieldSpec(from: decoder))
            case "au_becs_account_number":
                self = .au_becs_account_number(try BaseFieldSpec(from: decoder))
            case "au_becs_mandate":
                self = .au_becs_mandate
            case "afterpay_header":
                self = .afterpay_header
            case "sofort_billing_address":
                self = .sofort_billing_address(try SofortBillingAddress(from: decoder))
            case "iban":
                self = .iban(try BaseFieldSpec(from: decoder))
            case "sepa_mandate":
                self = .sepa_mandate
            default:
                fatalError("Unknown fieldType")
            }
        }
    }
}

extension FormSpec {
    struct BaseFieldSpec: Decodable, Equatable {
        /// A form URL encoded key, whose value is `PropertyItemSpec.apiValue`
        let apiPath: [String:String]?
    }
    struct NameFieldSpec: Decodable, Equatable {
        /// A form URL encoded key, whose value is `PropertyItemSpec.apiValue`
        let apiPath: [String:String]?
        /// An optional localizedId to control the label
        let label: LocalizedString?
    }
    struct SelectorSpec: Decodable, Equatable {
        struct PropertyItemSpec: Decodable, Equatable {
            /// The localized text to display for this item in the dropdown
            let displayText: String
            /// The value to send to the Stripe API if the customer selects this dropdown item
            let apiValue: String?
        }
        /// The dropdown's label
        let label: LocalizedString
        /// The list of items to display in the dropdown
        let items: [PropertyItemSpec]
        /// A form URL encoded key, whose value is `PropertyItemSpec.apiValue`
        let apiPath: [String:String]?

    }

    struct SofortBillingAddress: Decodable, Equatable {
        /// A form URL encoded key, whose value is `PropertyItemSpec.apiValue`
        let apiPath: [String:String]?
        /// A list of valid countries codes to be displayed
        let validCountryCodes: [String]
    }
}

extension FormSpec {
    enum LocalizedString: String, Decodable {
        case ideal_bank = "upe.labels.ideal.bank"
        case eps_bank =  "upe.labels.eps.bank"
        case p24_bank = "upe.labels.p24.bank"

        case nameLabel_given = "upe.labels.name.given"
        case nameLabel_family = "upe.labels.name.family"
        case nameLabel_full = "upe.labels.name.full"
        case nameLabel_onAccount = "upe.labels.name.onAccount"

        var localizedValue: String {
            switch self {
            case .ideal_bank:
                return String.Localized.ideal_bank
            case .eps_bank:
                return STPLocalizedString("EPS Bank", "Label title for EPS Bank")
            case .p24_bank:
                return STPLocalizedString("Przelewy24 Bank", "Label title for Przelewy24 Bank")

            case .nameLabel_given:
                return String.Localized.given_name
            case .nameLabel_family:
                return String.Localized.family_name
            case .nameLabel_full:
                return String.Localized.name
            case .nameLabel_onAccount:
                return String.Localized.nameOnAccount
            }
        }
    }
}
