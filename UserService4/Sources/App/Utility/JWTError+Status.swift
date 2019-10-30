import Vapor
import JWTKit

extension JWTError: AbortError {
    public var status: HTTPResponseStatus {
        switch self.failureReason {
        case "exp": return .unauthorized
        default: return .internalServerError
        }
    }
}
