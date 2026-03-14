# frozen_string_literal: true

RSpec.describe Legion::Extensions::FrameSemantics::Helpers::FrameEngine do
  subject(:engine) { described_class.new }

  let(:frame) { engine.create_frame(name: :commercial_transaction, domain: :commerce) }

  before do
    frame.add_slot(name: :buyer)
    frame.add_slot(name: :seller)
    frame.add_slot(name: :goods)
  end

  describe '#create_frame' do
    it 'returns a Frame object' do
      f = engine.create_frame(name: :motion, domain: :physics)
      expect(f).to be_a(Legion::Extensions::FrameSemantics::Helpers::Frame)
    end

    it 'creates frame with slots from hash' do
      f = engine.create_frame(
        name:   :competition,
        domain: :sports,
        slots:  { winner: { type: :core, required: true }, loser: { type: :peripheral, required: false } }
      )
      expect(f.slots[:winner][:type]).to eq(:core)
      expect(f.slots[:loser][:type]).to eq(:peripheral)
    end
  end

  describe '#define_slot' do
    it 'adds a slot to an existing frame' do
      result = engine.define_slot(frame_id: frame.id, name: :price)
      expect(result).to be_a(Legion::Extensions::FrameSemantics::Helpers::Frame)
      expect(frame.slots[:price]).not_to be_nil
    end

    it 'returns nil for unknown frame_id' do
      expect(engine.define_slot(frame_id: 'bogus', name: :price)).to be_nil
    end
  end

  describe '#fill_slot' do
    it 'fills a slot and returns true' do
      expect(engine.fill_slot(frame_id: frame.id, slot_name: :buyer, filler: 'Alice')).to be true
    end

    it 'returns false for unknown frame' do
      expect(engine.fill_slot(frame_id: 'bogus', slot_name: :buyer, filler: 'x')).to be false
    end

    it 'activates the frame when slot is filled' do
      initial = frame.activation
      engine.fill_slot(frame_id: frame.id, slot_name: :buyer, filler: 'Alice')
      expect(frame.activation_count).to be >= 1
      expect(frame.activation).to be >= initial
    end
  end

  describe '#instantiate_frame' do
    before do
      engine.fill_slot(frame_id: frame.id, slot_name: :buyer, filler: 'Alice')
      engine.fill_slot(frame_id: frame.id, slot_name: :seller, filler: 'Bob')
    end

    it 'creates a FrameInstance snapshot' do
      inst = engine.instantiate_frame(frame_id: frame.id, context: 'coffee shop')
      expect(inst).to be_a(Legion::Extensions::FrameSemantics::Helpers::FrameInstance)
      expect(inst.frame_id).to eq(frame.id)
      expect(inst.context).to eq('coffee shop')
    end

    it 'returns nil for unknown frame' do
      expect(engine.instantiate_frame(frame_id: 'bogus', context: 'x')).to be_nil
    end

    it 'snapshots current slot fillers' do
      inst = engine.instantiate_frame(frame_id: frame.id, context: 'test')
      expect(inst.slot_fillers[:buyer]).to eq('Alice')
    end
  end

  describe '#add_frame_relation' do
    it 'adds a valid relation' do
      target = engine.create_frame(name: :transfer, domain: :commerce)
      result = engine.add_frame_relation(
        frame_id:        frame.id,
        relation:        :has_subframe,
        target_frame_id: target.id
      )
      expect(result).to be true
      expect(frame.relations.size).to eq(1)
    end

    it 'rejects invalid relation type' do
      result = engine.add_frame_relation(
        frame_id:        frame.id,
        relation:        :invalid_relation,
        target_frame_id: SecureRandom.uuid
      )
      expect(result).to be false
    end

    it 'returns false for unknown frame_id' do
      expect(
        engine.add_frame_relation(frame_id: 'bogus', relation: :uses, target_frame_id: SecureRandom.uuid)
      ).to be false
    end
  end

  describe '#activate_frame' do
    it 'activates an existing frame' do
      initial_count = frame.activation_count
      engine.activate_frame(frame_id: frame.id)
      expect(frame.activation_count).to eq(initial_count + 1)
    end

    it 'returns false for unknown frame' do
      expect(engine.activate_frame(frame_id: 'bogus')).to be false
    end
  end

  describe '#active_frames' do
    it 'returns frames with activation > 0.5' do
      5.times { engine.activate_frame(frame_id: frame.id) }
      expect(engine.active_frames).to include(frame)
    end

    it 'excludes frames below threshold' do
      new_engine = described_class.new
      f = new_engine.create_frame(name: :cold, domain: :test)
      100.times { f.decay! }
      expect(new_engine.active_frames).not_to include(f)
    end
  end

  describe '#frames_by_domain' do
    before do
      engine.create_frame(name: :motion, domain: :physics)
      engine.create_frame(name: :competition, domain: :sports)
    end

    it 'returns only frames matching the domain' do
      result = engine.frames_by_domain(domain: :physics)
      expect(result.map(&:domain)).to all(eq(:physics))
    end
  end

  describe '#related_frames' do
    it 'traverses relations to return related frames' do
      target = engine.create_frame(name: :payment, domain: :commerce)
      engine.add_frame_relation(frame_id: frame.id, relation: :has_subframe, target_frame_id: target.id)
      related = engine.related_frames(frame_id: frame.id)
      expect(related).to include(target)
    end

    it 'returns empty array for unknown frame' do
      expect(engine.related_frames(frame_id: 'bogus')).to eq([])
    end
  end

  describe '#most_activated' do
    it 'returns top N frames sorted by activation desc' do
      f2 = engine.create_frame(name: :motion, domain: :physics)
      5.times { engine.activate_frame(frame_id: frame.id) }
      result = engine.most_activated(limit: 2)
      expect(result.first).to eq(frame)
      expect(result).not_to include(f2) if result.size < 2
    end
  end

  describe '#instances_for_frame' do
    it 'returns all instances of a specific frame' do
      engine.instantiate_frame(frame_id: frame.id, context: 'ctx1')
      engine.instantiate_frame(frame_id: frame.id, context: 'ctx2')
      expect(engine.instances_for_frame(frame_id: frame.id).size).to eq(2)
    end
  end

  describe '#complete_frames' do
    it 'returns only complete frames' do
      engine.fill_slot(frame_id: frame.id, slot_name: :buyer,  filler: 'Alice')
      engine.fill_slot(frame_id: frame.id, slot_name: :seller, filler: 'Bob')
      engine.fill_slot(frame_id: frame.id, slot_name: :goods,  filler: 'coffee')
      expect(engine.complete_frames).to include(frame)
    end

    it 'excludes incomplete frames' do
      engine.fill_slot(frame_id: frame.id, slot_name: :buyer, filler: 'Alice')
      expect(engine.complete_frames).not_to include(frame)
    end
  end

  describe '#decay_all' do
    it 'decays all frame activations' do
      initial = frame.activation
      engine.decay_all
      expect(frame.activation).to be < initial
    end
  end

  describe '#prune_inactive' do
    it 'removes frames with activation <= 0.05' do
      f = engine.create_frame(name: :ghost, domain: :test)
      100.times { f.decay! }
      engine.prune_inactive
      expect(engine.instances_for_frame(frame_id: f.id)).to be_empty
    end

    it 'retains frames with activation above threshold' do
      5.times { engine.activate_frame(frame_id: frame.id) }
      engine.prune_inactive
      expect(engine.active_frames).to include(frame)
    end
  end

  describe '#to_h' do
    it 'returns stats hash with expected keys' do
      h = engine.to_h
      expect(h).to include(:frame_count, :instance_count, :active_count, :complete_count, :domains)
    end

    it 'reflects current state' do
      expect(engine.to_h[:frame_count]).to eq(1)
    end
  end
end
