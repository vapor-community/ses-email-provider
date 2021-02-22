import Vapor
import SotoSES
import Email

extension Application.Emails.Provider {
    public static func ses(client: AWSClient) -> Self {
        .init {
            $0.emails.use {
                SESEmailClientWrapper(ses: SES(client: client), eventLoop: $0.eventLoopGroup.next(), logger: $0.logger)
            }
        }
    }
}
