class ApplicationMailer < ActionMailer::Base
  include Roadie::Rails::Automatic
  layout "email"
end
