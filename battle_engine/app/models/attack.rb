# frozen_string_literal: true

class Attack < ApplicationRecord
  belongs_to :pokemon
  belongs_to :move

  validates :pokemon_id, uniqueness: { scope: :move_id }
  validate :pokemon_has_at_most_four_attacks

  private

  def pokemon_has_at_most_four_attacks
    return unless pokemon && pokemon.attacks.size > 4

    errors.add(:pokemon, 'cannot have more than 4 attacks')
  end
end
