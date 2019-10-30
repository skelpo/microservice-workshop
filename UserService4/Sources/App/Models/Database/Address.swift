import Fluent
import Vapor

final class Address: Content, Model {
    static let schema = "addresses"
    
    @ID(key: "id")
    var id: Int?
    
    @Field(key: "street")
    var street: String
    
    @Field(key: "city")
    var city: String
    
    @Field(key: "zip")
    var zip: String
    
    @Field(key: "userId")
    var userId: Int
    
    init() { }
    
    init(street: String, city: String, zip: String, userId: Int) {
        self.street = street
        self.city = city
        self.zip = zip
        self.userId = userId
    }
}
