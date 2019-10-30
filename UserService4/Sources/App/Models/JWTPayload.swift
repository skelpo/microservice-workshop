import Foundation
import Vapor
import JWTKit

struct JWTPayload: IdentifiableJWTPayload {
    let firstname: String?
    let lastname: String?
    let email: String
    let id: User.IDValue
    let status: Int = 0
    let exp: TimeInterval
    let iat: TimeInterval
    
    init(user: User, expiration: TimeInterval = 3600)throws {
        let now = Date().timeIntervalSince1970
        
        self.firstname = user.firstname
        self.lastname = user.lastname
        self.exp = now + expiration
        self.iat = now
        self.email = user.email
        self.id = try user.requireID()
    }
    
    func verify(using signer: JWTSigner) throws {
        let expiration = Date(timeIntervalSince1970: self.exp)
        try ExpirationClaim(value: expiration).verifyNotExpired()
    }
}
