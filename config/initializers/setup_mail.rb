require 'mail_tracking_interceptor'
ActionMailer::Base.register_interceptor(MailTrackingInterceptor::Interceptor)
ActionMailer::Base.register_interceptor(Dkim::Interceptor)
