import Foundation
import Email
import SotoSES

struct SESEmailClientWrapper: EmailClient {
    private let eventLoop: EventLoop
    private let logger: Logger
    private let ses: SES
    
    init(ses: SES, eventLoop: EventLoop, logger: Logger) {
        self.ses = ses
        self.eventLoop = eventLoop
        self.logger = logger
    }
    
    func send(_ messages: [EmailMessage]) -> EventLoopFuture<Void> {
        messages.map { message in
            let destination = SES.Destination(
                bccAddresses: message.bcc?.map(\.email),
                ccAddresses: message.cc?.map(\.email),
                toAddresses: message.to.map(\.email))
            
            let htmlContent = message.contents.compactMap { content -> String? in
                guard case let .html(html) = content else { return nil }
                return html
            }
            .first
            
            let textContent = message.contents.compactMap { content -> String? in
                guard case let .text(text) = content else { return nil }
                return text
            }
            .first
            
            let SESMessage = SES.Message(
                body: .init(
                    html: htmlContent != nil ? SES.Content(data: htmlContent!) : nil,
                    text: textContent != nil ? SES.Content(data: textContent!) : nil
                ),
                subject: .init(data: message.subject))
            
            var replyTo: [String]? = nil
            if let _replyTo = message.replyTo {
                replyTo = [_replyTo.email]
            }
            
            let request = SES.SendEmailRequest(destination: destination, message: SESMessage, replyToAddresses: replyTo, source: message.from.email)
            return ses.sendEmail(request, logger: self.logger, on: eventLoop)
                .transform(to: ())
        }
        .flatten(on: eventLoop)
    }
    
    func delegating(to eventLoop: EventLoop) -> EmailClient {
        SESEmailClientWrapper(ses: self.ses, eventLoop: eventLoop, logger: self.logger)
    }
}
