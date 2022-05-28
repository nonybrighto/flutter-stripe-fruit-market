//
//  PaymentSheetFormFactory+FormSpec.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

extension PaymentSheetFormFactory {

    func specFromJSONProvider(provider: FormSpecProvider = FormSpecProvider.shared) -> FormSpec? {
        guard let paymentMethodType = PaymentSheet.PaymentMethodType.string(from: paymentMethod) else {
            return nil
        }
        return provider.formSpec(for: paymentMethodType)
    }

    func makeFormElementFromSpec(spec: FormSpec) -> FormElement {
        let elements = makeFormElements(from: spec)
        return FormElement(autoSectioningElements: elements)
    }

    private func makeFormElements(from spec: FormSpec) -> [Element] {
        return spec.fields.map { elementSpec in
            switch elementSpec {
            case .name(let spec):
                return makeName(overrideLabel: spec.label?.localizedValue, apiPath: spec.apiPath?["v1"])
            case .email(let spec):
                return makeEmail(apiPath: spec.apiPath?["v1"])
            case .selector(let selectorSpec):
                let dropdownField = DropdownFieldElement(
                    items: selectorSpec.items.map { $0.displayText },
                    label: selectorSpec.label.localizedValue
                )
                return PaymentMethodElementWrapper(dropdownField) { dropdown, params in
                    let values = selectorSpec.items.map { $0.apiValue }
                    let selectedValue = values[dropdown.selectedIndex]
                    //TODO: Determine how to handle multiple versions
                    if let apiPathKey = selectorSpec.apiPath?["v1"] {
                        params.paymentMethodParams.additionalAPIParameters[apiPathKey] = selectedValue
                    }
                    return params
                }
            case .billing_address:
                return makeBillingAddressSection()
            case .affirm_header:
                return StaticElement(view: AffirmCopyLabel())
            case .klarna_header:
                return makeKlarnaCopyLabel()
            case .klarna_country(let spec):
                return makeKlarnaCountry(apiPath: spec.apiPath?["v1"])!
            case .au_becs_bsb_number(let spec):
                return makeBSB(apiPath: spec.apiPath?["v1"])
            case .au_becs_account_number(let spec):
                return makeAUBECSAccountNumber(apiPath: spec.apiPath?["v1"])
            case .au_becs_mandate:
                return makeAUBECSMandate()
            case .afterpay_header:
                return makeAfterpayClearpayHeader()!
            case .sofort_billing_address(let spec):
                return makeSofortBillingAddress(countryCodes: spec.validCountryCodes, apiPath: spec.apiPath?["v1"])
            case .iban(let spec):
                return makeIban(apiPath: spec.apiPath?["v1"])
            case .sepa_mandate:
                return makeSepaMandate()
            }
        }
    }
}
