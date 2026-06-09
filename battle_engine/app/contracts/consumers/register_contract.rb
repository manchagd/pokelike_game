# frozen_string_literal: true

require "dry-validation"

module Contracts
  module Consumers
    class RegisterContract < Dry::Validation::Contract
      params do
        required(:name).filled(:string)
      end
    end
  end
end
