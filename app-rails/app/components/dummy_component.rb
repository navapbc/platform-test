# frozen_string_literal: true

class DummyComponent < ViewComponent::Base
  def initialize(message:)
    @message = message
  end
end
