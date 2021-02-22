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
                bccAddresses: message.bcc?.map(\.description),
                ccAddresses: message.cc?.map(\.description),
                toAddresses: message.to.map(\.description))
            
            var htmlContent: SES.Content? = nil
            var textContent: SES.Content? = nil
            
            if let html = message.content.html { htmlContent = .init(data: html) }
            if let text = message.content.text { textContent = .init(data: text) }
            
            let SESMessage = SES.Message(
                body: .init(
                    html: htmlContent,
                    text: textContent
                ),
                subject: .init(data: message.subject))
            
            var replyTo: [String]? = nil
            if let _replyTo = message.replyTo {
                replyTo = [_replyTo.email]
            }
            
            let request = SES.SendEmailRequest(destination: destination, message: SESMessage, replyToAddresses: replyTo, source: message.from.description)
            return ses.sendEmail(request, logger: self.logger, on: eventLoop)
                .transform(to: ())
        }
        .flatten(on: eventLoop)
    }
    
    func delegating(to eventLoop: EventLoop) -> EmailClient {
        SESEmailClientWrapper(ses: self.ses, eventLoop: eventLoop, logger: self.logger)
    }
}
