# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BattleLog do
  describe 'associations' do
    it 'belongs to battle' do
      association = described_class.reflect_on_association(:battle)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid with a battle and message' do
      battle = create(:battle)
      battle_log = build(:battle_log, battle: battle, message: 'Test message')
      expect(battle_log).to be_valid
    end

    it 'is invalid without a message' do
      battle_log = build(:battle_log, message: nil)
      expect(battle_log).not_to be_valid
      expect(battle_log.errors[:message]).to include("can't be blank")
    end
  end

  describe 'payload serialization and contract validation' do
    it 'serializes battle_logs in battle_status and passes contract validation' do
      battle = create(:battle)
      create(:battle_log, battle: battle, message: 'Log 1')
      create(:battle_log, battle: battle, message: 'Log 2')

      payload = Messages::BattleEvents::Payloads.battle_status(battle)
      expect(payload[:battle_logs]).to be_an(Array)
      expect(payload[:battle_logs].size).to eq(2)
      expect(payload[:battle_logs].first[:message]).to eq('Log 1')
      expect(payload[:battle_logs].first[:created_at]).to be_a(String)

      # Validate with Contract
      contract = Contracts::Publishers::BattleStatusContract.new
      result = contract.call(payload.merge(timestamp: Time.now.iso8601))
      expect(result).to be_success
    end
  end
end
