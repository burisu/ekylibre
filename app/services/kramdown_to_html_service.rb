# frozen_string_literal: true

require 'kramdown'
require 'gitlab_kramdown'

class KramdownToHtmlService
  def self.call(...)
    new(...).call
  end

  def self.pdf(...)
    new(...).pdf
  end

  def initialize(content:)
    @content = content
  end

  def call
    Kramdown::Document.new(content, input: 'GitlabKramdown').to_html.html_safe
  end

  def pdf
    Kramdown::Document.new(content, input: 'GitlabKramdown').to_pdf
  end

  private

    attr_reader :content
end
