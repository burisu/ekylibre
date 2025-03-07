# frozen_string_literal: true

module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :observations, as: :subject
  end
end
