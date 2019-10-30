import JWTDataProvider
import JWTMiddleware
import CryptoSwift
import SendGrid
import Crypto
import Fluent
import Vapor
import JWT

final class AuthController: RouteCollection {
    private let jwtService: JWTService
    private let sendGridClient: SendGridClient
    
    init(jwtService: JWTService, sendGridClient: SendGridClient) {
        self.jwtService = jwtService
        self.sendGridClient = sendGridClient
    }
    
    func boot(router: Router) throws {
        router.post(NewUserInput.self, at: "register", use: register)
        router.grouped(JWTAuthenticatableMiddleware<User>()).post("login", use: login)
        router.post(RenewAccessTokenInput.self, at: "accessToken", use: refreshAccessToken)        
    }
    
    func register(_ request: Request, _ userData: NewUserInput)throws -> Future<UserSuccessResponse> {
        let user = try User(userData.email, userData.firstname, userData.lastname, userData.password)
        try user.validate()
        
        let count = User.query(on: request).filter(\.email == user.email).count()
        return count.map(to: User.self) { count in
            guard count < 1 else { throw Abort(.badRequest, reason: "This email is already registered.") }
            return user
        }.flatMap(to: User.self) { (user) in
            print("setting the password: ", userData.password)
            user.password = try BCrypt.hash(userData.password)
            
            return user.save(on: request)
        }.flatMap(to: User.self) { (user) in
            let subject: String = "Your Registration"
            let body: String = "Welcome!"
            
            let name = [user.firstname, user.lastname].compactMap({ $0 }).joined(separator: " ")
            let from = EmailAddress(email: "info@domain.com", name: nil)
            let address = EmailAddress(email: user.email, name: name)
            let header = Personalization(to: [address], subject: subject)
            let email = SendGridEmail(personalizations: [header], from: from, subject: subject, content: [[
                "type": "text",
                "value": body
                ]])
            
            return try self.sendGridClient.send([email], on: request).transform(to: user)
        }
        .response(on: request)
    }
    
    func refreshAccessToken(_ request: Request, _ renewAccessTokenData: RenewAccessTokenInput)throws -> Future<RefreshTokenResponse> {
        let refreshJWT = try JWT<RefreshToken>(from: renewAccessTokenData.refreshToken, verifiedUsing: self.jwtService.signer)
        try refreshJWT.payload.verify(using: self.jwtService.signer)

        let userID = refreshJWT.payload.id
        let user = User.find(userID, on: request).unwrap(or: Abort(.badRequest, reason: "No user found with ID '\(userID)'."))
        
        return user.flatMap(to: (JSON, Payload).self) { user in
            
            let payload = try App.Payload(user: user)
            return try request.payloadData(self.jwtService.sign(payload), with: ["userId": "\(user.requireID())"], as: JSON.self).and(result: payload)
        }.map(to: RefreshTokenResponse.self) { payloadData in
            let payload = try payloadData.0.merge(payloadData.1.json())
            
            let token = try self.jwtService.sign(payload)
            return RefreshTokenResponse(accessToken: token)
        }
    }
    
    func login(_ request: Request)throws -> Future<LoginResponse> {
        let user = try request.requireAuthenticated(User.self)
        let payload = try Payload(user: user).json()
            
        let accessToken = try self.jwtService.sign(payload)
        let refreshToken = try self.jwtService.sign(RefreshToken(user: user))
        
        let userResponse = UserResponse(user: user, addresses: nil)
        return request.future(LoginResponse(accessToken: accessToken, refreshToken: refreshToken, user: userResponse))
    }
}
