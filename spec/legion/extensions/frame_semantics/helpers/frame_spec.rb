# frozen_string_literal: true

RSpec.describe Legion::Extensions::FrameSemantics::Helpers::Frame do
  subject(:frame) { described_class.new(name: :commercial_transaction, domain: :commerce) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(frame.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets name and domain' do
      expect(frame.name).to eq(:commercial_transaction)
      expect(frame.domain).to eq(:commerce)
    end

    it 'starts with default activation' do
      expect(frame.activation).to eq(Legion::Extensions::FrameSemantics::Helpers::DEFAULT_ACTIVATION)
    end

    it 'starts with zero activation_count' do
      expect(frame.activation_count).to eq(0)
    end

    it 'starts with empty slots and relations' do
      expect(frame.slots).to be_empty
      expect(frame.relations).to be_empty
    end
  end

  describe '#add_slot' do
    it 'adds a core slot by default' do
      frame.add_slot(name: :buyer)
      expect(frame.slots[:buyer][:type]).to eq(:core)
      expect(frame.slots[:buyer][:required]).to be true
      expect(frame.slots[:buyer][:filler]).to be_nil
    end

    it 'adds a peripheral slot when specified' do
      frame.add_slot(name: :payment_method, slot_type: :peripheral, required: false)
      expect(frame.slots[:payment_method][:type]).to eq(:peripheral)
      expect(frame.slots[:payment_method][:required]).to be false
    end

    it 'returns self for chaining' do
      result = frame.add_slot(name: :seller)
      expect(result).to be(frame)
    end
  end

  describe '#fill_slot' do
    before { frame.add_slot(name: :buyer) }

    it 'fills a slot and returns true' do
      result = frame.fill_slot(name: :buyer, filler: 'Alice')
      expect(result).to be true
      expect(frame.slots[:buyer][:filler]).to eq('Alice')
    end

    it 'boosts activation when slot is filled' do
      initial = frame.activation
      frame.fill_slot(name: :buyer, filler: 'Alice')
      expect(frame.activation).to be > initial
    end

    it 'returns false for unknown slot' do
      expect(frame.fill_slot(name: :unknown, filler: 'x')).to be false
    end
  end

  describe '#clear_slot' do
    before do
      frame.add_slot(name: :buyer)
      frame.fill_slot(name: :buyer, filler: 'Alice')
    end

    it 'clears the slot filler' do
      frame.clear_slot(name: :buyer)
      expect(frame.slots[:buyer][:filler]).to be_nil
    end

    it 'returns true for existing slot' do
      expect(frame.clear_slot(name: :buyer)).to be true
    end

    it 'returns false for unknown slot' do
      expect(frame.clear_slot(name: :ghost)).to be false
    end
  end

  describe '#core_slots' do
    before do
      frame.add_slot(name: :buyer, slot_type: :core)
      frame.add_slot(name: :seller, slot_type: :core)
      frame.add_slot(name: :note, slot_type: :peripheral)
    end

    it 'returns only core slots' do
      expect(frame.core_slots.keys).to contain_exactly(:buyer, :seller)
    end
  end

  describe '#filled_slots' do
    before do
      frame.add_slot(name: :buyer)
      frame.add_slot(name: :seller)
      frame.fill_slot(name: :buyer, filler: 'Alice')
    end

    it 'returns only filled slots' do
      expect(frame.filled_slots.keys).to eq([:buyer])
    end
  end

  describe '#completion_ratio' do
    it 'returns 0.0 with no slots' do
      expect(frame.completion_ratio).to eq(0.0)
    end

    it 'returns correct fraction of filled core slots' do
      frame.add_slot(name: :buyer)
      frame.add_slot(name: :seller)
      frame.add_slot(name: :goods)
      frame.fill_slot(name: :buyer, filler: 'Alice')
      expect(frame.completion_ratio).to be_within(0.001).of(1.0 / 3.0)
    end

    it 'ignores peripheral slots in ratio' do
      frame.add_slot(name: :buyer, slot_type: :core)
      frame.add_slot(name: :note, slot_type: :peripheral)
      frame.fill_slot(name: :buyer, filler: 'Alice')
      expect(frame.completion_ratio).to eq(1.0)
    end
  end

  describe '#complete?' do
    it 'returns false when completion is below threshold' do
      frame.add_slot(name: :buyer)
      frame.add_slot(name: :seller)
      frame.add_slot(name: :goods)
      frame.fill_slot(name: :buyer, filler: 'Alice')
      expect(frame.complete?).to be false
    end

    it 'returns true when all core slots are filled' do
      frame.add_slot(name: :buyer)
      frame.fill_slot(name: :buyer, filler: 'Alice')
      expect(frame.complete?).to be true
    end
  end

  describe '#activate!' do
    it 'boosts activation and increments count' do
      initial = frame.activation
      frame.activate!
      expect(frame.activation).to be > initial
      expect(frame.activation_count).to eq(1)
    end

    it 'clamps activation at 1.0' do
      10.times { frame.activate! }
      expect(frame.activation).to eq(1.0)
    end
  end

  describe '#decay!' do
    it 'reduces activation' do
      initial = frame.activation
      frame.decay!
      expect(frame.activation).to be < initial
    end

    it 'clamps activation at 0.0' do
      100.times { frame.decay! }
      expect(frame.activation).to eq(0.0)
    end
  end

  describe '#activation_label' do
    it 'returns :dominant for high activation' do
      10.times { frame.activate! }
      expect(frame.activation_label).to eq(:dominant)
    end

    it 'returns :inactive for very low activation' do
      100.times { frame.decay! }
      expect(frame.activation_label).to eq(:inactive)
    end

    it 'returns :primed for mid activation around 0.5' do
      frame.instance_variable_set(:@activation, 0.5)
      expect(frame.activation_label).to eq(:primed)
    end
  end

  describe '#add_relation' do
    it 'appends a relation entry' do
      other_id = SecureRandom.uuid
      frame.add_relation(relation: :inherits_from, target_frame_id: other_id)
      expect(frame.relations.size).to eq(1)
      expect(frame.relations.first[:relation]).to eq(:inherits_from)
      expect(frame.relations.first[:target_frame_id]).to eq(other_id)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = frame.to_h
      expect(h).to include(:id, :name, :domain, :slots, :relations,
                           :activation, :activation_label, :activation_count,
                           :completion_ratio, :complete, :created_at)
    end
  end
end
