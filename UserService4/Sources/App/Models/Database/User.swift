import Fluent
//import Validation
//import Crypto
import Vapor
//import JWTMiddleware

final class User: Model {
    
    static let schema: String = "users"
    
    @ID(key: "id")
    var id: Int?
    
    @Field(key: "firstname")
    var firstname: String?
    
    @Field(key: "lastname")
    var lastname: String?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deletedAt", on: .delete)
    var deletedAt: Date?
    
    init() {}
    
    init(_ email: String) throws {
        self.email = email
        self.password = ""
    }
    
    convenience init(_ email: String, _ firstName: String? = nil, _ lastName: String? = nil, _ password: String)throws {
        try self.init(email)
        
        self.firstname = firstName
        self.lastname = lastName
        self.password = try BCryptDigest().hash(password)
    }

    func addresses(on connection: Database) -> QueryBuilder<Address>? {
        if let id = self.id {
            return Address.query(on: connection).filter(\Address.$userId == id)
        }
        return nil
    }
    
    func response(on database: Database) -> EventLoopFuture<UserSuccessResponse> {
        if let address = self.addresses(on: database) {
            return address.all().map { addresses in
                let user = UserResponse(user: self, addresses: addresses)
                return UserSuccessResponse(user: user)
            }
        }
        else {
            return database.eventLoop.makeFailedFuture(Abort(.internalServerError))
        }
    }
    
/*    static func validations() throws -> Validations<User> {
        var validations = Validations(User.self)
        try validations.add(\.password, .ascii && .count(6...))
        try validations.add(\.email, .email)
        return validations
    }*/
    /*
    static var usernameKey: WritableKeyPath<User, String> {
        return \.email
    }*/
    
    func accessToken(on request: Request) throws -> EventLoopFuture<JWTPayload> {
        return request.eventLoop.future(try JWTPayload(user: self))
    }
}

