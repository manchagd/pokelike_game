# frozen_string_literal: true

module Contracts
  module Consumers
    class RegisterContract < Dry::Validation::Contract
      params do
        required(:name).filled(:string)
        optional(:timestamp).maybe(:string)
      end
    end
  end
end
