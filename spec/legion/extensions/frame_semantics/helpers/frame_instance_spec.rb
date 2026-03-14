# frozen_string_literal: true

RSpec.describe Legion::Extensions::FrameSemantics::Helpers::FrameInstance do
  let(:frame_id)    { SecureRandom.uuid }
  let(:frame_name)  { :commercial_transaction }
  let(:slot_fillers) do
    { buyer: 'Alice', seller: 'Bob', goods: nil }
  end

  subject(:instance) do
    described_class.new(
      frame_id:     frame_id,
      frame_name:   frame_name,
      slot_fillers: slot_fillers,
      context:      'buying coffee',
      confidence:   0.85
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(instance.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores frame metadata' do
      expect(instance.frame_id).to eq(frame_id)
      expect(instance.frame_name).to eq(frame_name)
    end

    it 'duplicates slot_fillers' do
      inst = instance
      slot_fillers[:buyer] = 'Charlie'
      expect(inst.slot_fillers[:buyer]).to eq('Alice')
    end

    it 'stores context and confidence' do
      expect(instance.context).to eq('buying coffee')
      expect(instance.confidence).to eq(0.85)
    end
  end

  describe '#filled_count' do
    it 'counts non-nil fillers' do
      expect(instance.filled_count).to eq(2)
    end

    it 'returns 0 when all fillers are nil' do
      empty = described_class.new(
        frame_id: frame_id, frame_name: frame_name,
        slot_fillers: { buyer: nil }, context: 'x'
      )
      expect(empty.filled_count).to eq(0)
    end
  end

  describe '#complete?' do
    it 'returns true when at least one slot is filled' do
      expect(instance.complete?).to be true
    end

    it 'returns false when all slots are nil' do
      empty = described_class.new(
        frame_id: frame_id, frame_name: frame_name,
        slot_fillers: { buyer: nil }, context: 'x'
      )
      expect(empty.complete?).to be false
    end
  end

  describe '#to_h' do
    it 'returns expected keys' do
      h = instance.to_h
      expect(h).to include(:id, :frame_id, :frame_name, :slot_fillers,
                           :context, :confidence, :filled_count, :complete, :created_at)
    end

    it 'includes filled_count and complete flag' do
      h = instance.to_h
      expect(h[:filled_count]).to eq(2)
      expect(h[:complete]).to be true
    end
  end
end
