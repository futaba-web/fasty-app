# frozen_string_literal: true

require "rails_helper"

RSpec.describe MeditationLog, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it "is valid with duration_sec and user" do
      log = described_class.new(
        user: user,
        duration_sec: 180,
        started_at: Time.zone.parse("2025-01-01 09:00")
      )

      expect(log).to be_valid
    end

    it "is invalid without a user" do
      log = described_class.new(
        duration_sec: 180
      )

      expect(log).not_to be_valid
      expect(log.errors[:user]).to be_present
    end

    it "is invalid when duration_sec is negative" do
      log = described_class.new(
        user: user,
        duration_sec: -10
      )

      expect(log).not_to be_valid
      expect(log.errors[:duration_sec]).to be_present
    end
  end

  describe "persistence" do
    it "can be saved to the database" do
      log = described_class.new(
        user: user,
        duration_sec: 120
      )

      expect { log.save! }.to change { described_class.count }.by(1)
    end
  end
end
