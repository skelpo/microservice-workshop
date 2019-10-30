import SendGrid
import Fluent
import Vapor
import JWTKit
import OpenCrypto

final class AuthController: RouteCollection {
    private let sendGridClient: SendGridClient
    
    func boot(routes: RoutesBuilder) throws {
        routes.post("register", use: register)
        routes.post("login", use: login)
        routes.post("accessToken", use: refreshAccessToken)
    }
    
    
    init(sendGridClient: SendGridClient) {
        self.sendGridClient = sendGridClient
    }
    
    func register(_ request: Request)throws -> EventLoopFuture<UserSuccessResponse> {
        let userData = try request.content.decode(NewUserInput.self)
        
        let user = try User(userData.email, userData.firstname, userData.lastname, userData.password)
        //try user.validate()
        
        let count = User.query(on: request.db).filter(\.$email == user.email).count()
        return count.flatMap { count -> EventLoopFuture<User> in
            if count > 0 {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "This email is already registered."))
            }
            return request.eventLoop.makeSucceededFuture(user)
        }.flatMap { user -> EventLoopFuture<User> in
            user.password = SHA256.hash(data: user.password.data(using: .utf8)!).description
            return user.save(on: request.db).transform(to: user)
        }.flatMap { user -> EventLoopFuture<User> in
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
            return self.sendGridClient.send([email], on: request).transform(to: user)
        }
        .response(on: request.make())
    }
    
    func refreshAccessToken(_ request: Request)throws -> EventLoopFuture<RefreshTokenResponse> {

        let signer = request.make(JWTSigner.self)
        
        let renewAccessTokenData = try request.content.decode(RenewAccessTokenInput.self)
        
        let refreshJWT = try JWT<RefreshToken>(from: renewAccessTokenData.refreshToken.data(using: .utf8)!, verifiedBy: signer)
        
        let userId = (refreshJWT.payload as RefreshToken).id
        let user = User.query(on: request.db).filter(\.$id == userId).first()
        
        return user.flatMap { user in
            if let user = user {
                do {
                    let accessToken = try JWT(payload: try JWTPayload(user: user)).sign(using: signer)
                    
                    return request.eventLoop.makeSucceededFuture(RefreshTokenResponse(accessToken: String(bytes: accessToken, encoding: .utf8)!))
                }
                catch let error {
                    return request.eventLoop.makeFailedFuture(error)
                }
            }
            else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No user found."))
            }
            
        }
    }
    
    func login(_ request: Request)throws -> EventLoopFuture<LoginResponse> {
        
        let content = try request.content.decode(LoginInput.self)
        
        return User.query(on: request.db).filter(\.$email == content.email).all().flatMap { users in
            if users.count == 0 {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No user found for this email."))
            }
            
            let user = users.first!
            
            if user.password == SHA256.hash(data: content.password.data(using: .utf8)!).description {
                do {
                    let signer = request.make(JWTSigner.self)
                    let accessToken = try JWT(payload: try JWTPayload(user: user)).sign(using: signer)
                    let refreshToken = try JWT(payload: try RefreshToken(user: user)).sign(using: signer)
//                let refreshToken = try self.jwtService.sign(RefreshToken(user: user))

                    let userResponse = UserResponse(user: user, addresses: nil)
                    return request.eventLoop.makeSucceededFuture(LoginResponse(accessToken: String(bytes: accessToken, encoding: .utf8)!, refreshToken: String(bytes: refreshToken, encoding: .utf8)!, user: userResponse))
                }
                catch let error {
                    return request.eventLoop.makeFailedFuture(error)
                }
            }
            else {
                return request.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Wrong password."))
            }
            
        }
        
        
    }
}
