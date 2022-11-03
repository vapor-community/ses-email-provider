import Vapor
import SotoSES
import Email

public extension Application.Emails.Provider {
    static func ses(client: SES) -> Self {
        .init {
            $0.emails.use {
                SESEmailClientWrapper(ses: client, eventLoop: $0.eventLoopGroup.next(), logger: $0.logger)
            }
        }
    }
}
