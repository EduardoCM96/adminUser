//
//  User.swift
//  adminUser
//
//  Created by Eduardo Carranza Maqueda on 30/03/25.
//

import Foundation
import RealmSwift

class Address: Object, Codable {
    @Persisted var street: String = ""
    @Persisted var suite: String = ""
    @Persisted var city: String = ""
    @Persisted var zipcode: String = ""
    @Persisted var lat: String = ""
    @Persisted var lng: String = ""
    
    enum CodingKeys: String, CodingKey {
        case street, suite, city, zipcode
        case geo
    }
    
    enum GeoKeys: String, CodingKey {
        case lat, lng
    }
    
    required override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        street = try container.decode(String.self, forKey: .street)
        suite = try container.decode(String.self, forKey: .suite)
        city = try container.decode(String.self, forKey: .city)
        zipcode = try container.decode(String.self, forKey: .zipcode)
        
        let geoContainer = try container.nestedContainer(keyedBy: GeoKeys.self, forKey: .geo)
        lat = try geoContainer.decode(String.self, forKey: .lat)
        lng = try geoContainer.decode(String.self, forKey: .lng)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(street, forKey: .street)
        try container.encode(suite, forKey: .suite)
        try container.encode(city, forKey: .city)
        try container.encode(zipcode, forKey: .zipcode)
        
        var geoContainer = container.nestedContainer(keyedBy: GeoKeys.self, forKey: .geo)
        try geoContainer.encode(lat, forKey: .lat)
        try geoContainer.encode(lng, forKey: .lng)
    }
}

class Company: Object, Codable {
    @Persisted var name: String = ""
    @Persisted var catchPhrase: String = ""
    @Persisted var bs: String = ""
    
    required override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        catchPhrase = try container.decode(String.self, forKey: .catchPhrase)
        bs = try container.decode(String.self, forKey: .bs)
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case catchPhrase
        case bs
    }
}

class User: Object, Codable, Identifiable {
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var name: String = ""
    @Persisted var username: String = ""
    @Persisted var email: String = ""
    @Persisted var phone: String = ""
    @Persisted var website: String = ""
    @Persisted var address: Address?
    @Persisted var company: Company?
    @Persisted var isDeleted: Bool = false
    @Persisted var isLocalOnly: Bool = false
    
    required override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decode(String.self, forKey: .phone)
        website = try container.decode(String.self, forKey: .website)
        address = try container.decode(Address.self, forKey: .address)
        company = try container.decode(Company.self, forKey: .company)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encode(phone, forKey: .phone)
        try container.encode(website, forKey: .website)
        try container.encode(address, forKey: .address)
        try container.encode(company, forKey: .company)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, username, email, phone, website, address, company
    }
}
