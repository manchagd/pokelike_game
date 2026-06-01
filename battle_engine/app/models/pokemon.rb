# frozen_string_literal: true

class Pokemon < ApplicationRecord
  GENDERS = [
    MALE = "Male",
    FEMALE = "Female"
  ].freeze

  has_and_belongs_to_many :teams, join_table: :team_pokemons
  belongs_to :pokemon_templates

  validates :nickname, length: { maximum: 10 }
  validates :gender, inclusion: { in: GENDERS }, allow_nil: true
  validates :nature, inclusion: { in: Nature::LIST }
  validates :weight, presence: true, numericality: true
  validates :lvl, presence: true, numericality: { only_integer: true }
  validates :teratype, inclusion: { in: Types::LIST }, allow_nil: true
end
