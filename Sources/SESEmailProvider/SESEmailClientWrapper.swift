import Foundation
import Email
import SotoSES

public struct SESEmailClientWrapper: EmailClient {
    private let eventLoop: EventLoop
    private let logger: Logger
    private let ses: SES
    
    public init(ses: SES, eventLoop: EventLoop, logger: Logger) {
        self.ses = ses
        self.eventLoop = eventLoop
        self.logger = logger
    }
    
    public func send(_ messages: [EmailMessage]) -> EventLoopFuture<Void> {
        messages.map { message in
            let destination = SES.Destination(
                bccAddresses: message.bcc?.map(\.fullAddress),
                ccAddresses: message.cc?.map(\.fullAddress),
                toAddresses: message.to.map(\.fullAddress)
            )
            
            var htmlContent: SES.Content? = nil
            var textContent: SES.Content? = nil
            
            switch message.content {
            case let .text(text):
                textContent = .init(data: text)
            case let .html(html):
                htmlContent = .init(data: html)
            case let .universal(text, html):
                textContent = .init(data: text)
                htmlContent = .init(data: html)
            }
            
            let sesMessage = SES.Message(
                body: .init(
                    html: htmlContent,
                    text: textContent
                ),
                subject: .init(data: message.subject)
            )
            
            var replyTo: [String]? = nil
            if let _replyTo = message.replyTo {
                replyTo = [_replyTo.email]
            }
            
            let request = SES.SendEmailRequest(
                destination: destination,
                message: sesMessage,
                replyToAddresses: replyTo,
                source: message.from.fullAddress
            )
            return ses.sendEmail(request, logger: self.logger, on: eventLoop)
                .transform(to: ())
        }
        .flatten(on: eventLoop)
    }
    
    public func delegating(to eventLoop: EventLoop) -> SESEmailClientWrapper {
        SESEmailClientWrapper(ses: self.ses, eventLoop: eventLoop, logger: self.logger)
    }
}
