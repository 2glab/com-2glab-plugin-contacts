import Foundation
import Contacts

@objc(PhonebookContacts) class PhonebookContacts : CDVPlugin {
    @objc(list:)
    func list(command: CDVInvokedUrlCommand) {
        self.commandDelegate!.run(inBackground: {
            var results = [[String: Any]]()

            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            let keysToFetch = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactBirthdayKey,
                CNContactPostalAddressesKey,
                CNContactEmailAddressesKey,
                CNContactPhoneNumbersKey,
                CNContactUrlAddressesKey,
                CNContactNoteKey] as [Any]

            let store = CNContactStore()
            store.requestAccess(for: .contacts, completionHandler: {
                granted, error in

                let request = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])
                var cnContacts = [CNContact]()

                do {
                    try store.enumerateContacts(with: request){
                        (contact, cursor) -> Void in
                        cnContacts.append(contact)
                    }
                } catch let error {
                    NSLog("Fetch contact error: \(error)")
                }

                for contact in cnContacts {
                    // Phone numbers
                    var phoneNumbers: [[String: Any]] = [];
                    for phoneNumber in contact.phoneNumbers {
                        if let number = phoneNumber.value as? CNPhoneNumber,
                            let label = phoneNumber.label {
                            let localizedLabel = CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: label)

                            phoneNumbers.append(["id": phoneNumber.identifier, "type": localizedLabel, "value": number.stringValue])
                        }
                    }

                    // Emails
                    var emailAddresses: [[String: Any]] = [];
                    for emailAddress in contact.emailAddresses {
                        if let label = emailAddress.label {
                            let localizedLabel =  CNLabeledValue<NSString>.localizedString(forLabel: label)

                            emailAddresses.append(["id": emailAddress.identifier, "type": localizedLabel, "value": emailAddress.value])
                        }
                    }

                    // URL's
                    var urlAddresses: [[String: Any]] = [];
                    for urlAddress in contact.urlAddresses {
                        if let label = urlAddress.label {
                            let localizedLabel =  CNLabeledValue<NSString>.localizedString(forLabel: label)

                            urlAddresses.append(["id": urlAddress.identifier, "type": localizedLabel, "value": urlAddress.value])
                        }
                    }

                    // Postal addresses
                    var postalAddresses: [[String: Any]]  = [];
                    for postalAddress in contact.postalAddresses {
                        if let label = postalAddress.label {
                            let localizedLabel = CNLabeledValue<CNPostalAddress>.localizedString(forLabel: label)

                            postalAddresses.append(["id": postalAddress.identifier,
                                                    "type": localizedLabel,
                                                    "streetAddress": postalAddress.value.street,
                                                    "locality": postalAddress.value.city,
                                                    "region": postalAddress.value.state,
                                                    "country": postalAddress.value.country,
                                                    "postalCode": postalAddress.value.isoCountryCode])
                        }
                    }


                    let dict: [String: Any] = [
                        "id": contact.identifier,
                        "name": ["familyName": contact.familyName, "givenName": contact.givenName, "middleName": contact.middleName],
                        "birthday": contact.birthday != nil ? formatter.string(from: contact.birthday!.date!) : "",
                        "note": contact.note,
                        "phoneNumbers": phoneNumbers,
                        "emails": emailAddresses,
                        "urls": urlAddresses,
                        "addresses": postalAddresses
                    ]
                    results.append(dict);
                }

                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: results)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            })
        })
    }
}
