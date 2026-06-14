# frozen_string_literal: true

class Pokemon < ApplicationRecord
  GENDERS = [
    MALE = 'Male',
    FEMALE = 'Female'
  ].freeze

  belongs_to :team
  belongs_to :pokemon_template
  has_many :attacks, dependent: :destroy
  has_many :moves, through: :attacks
  has_many :pokemon_battle_snapshots, dependent: :destroy

  validates :nickname, length: { maximum: 10 }
  validates :gender, inclusion: { in: GENDERS }, allow_nil: true
  validates :nature, inclusion: { in: Nature::LIST }
  validates :weight, presence: true, numericality: true
  validates :lvl, presence: true, numericality: { only_integer: true }
  validates :teratype, inclusion: { in: Types::LIST }, allow_nil: true
end
