# frozen_string_literal: true

# Renders mails whose body is stored in EmailTemplate (Liquid syntax),
# looked up by "<mailer_name>/<action_name>" path. Replaces panoramic + liquid-rails.
module Templatable
  extend ActiveSupport::Concern

  def full_from(user)
    address = Mail::Address.new user.email
    address.display_name = user.full_name
    address.format
  end

  # Values exposed to Liquid templates. Override in mailers.
  def liquid_assigns
    {}
  end

  # Calls `mail` with the body taken from the matching EmailTemplate.
  def mail_with_template(**headers)
    template = find_email_template
    return mail(**headers) if template.nil?

    body = Liquid::Template.parse(template.body.to_s).render(liquid_assigns.deep_stringify_keys)
    mail(**headers) do |format|
      format.html { render html: body.html_safe }
    end
  end

  private

    def find_email_template
      templates = EmailTemplate.where(path: "#{mailer_name}/#{action_name}")
      templates.find_by(locale: I18n.locale.to_s) ||
        templates.find_by(locale: [nil, '']) ||
        templates.order(by_default: :desc, id: :asc).first
    end
end
