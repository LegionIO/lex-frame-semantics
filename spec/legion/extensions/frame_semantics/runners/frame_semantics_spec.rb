# frozen_string_literal: true

require 'legion/extensions/frame_semantics/helpers/client'

RSpec.describe Legion::Extensions::FrameSemantics::Runners::FrameSemantics do
  let(:client) { Legion::Extensions::FrameSemantics::Helpers::Client.new }

  describe '#create_semantic_frame' do
    it 'creates a frame and returns its id' do
      result = client.create_semantic_frame(name: :commercial_transaction, domain: :commerce)
      expect(result[:created]).to be true
      expect(result[:frame_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:name]).to eq(:commercial_transaction)
    end
  end

  describe '#define_frame_slot' do
    let(:frame_id) { client.create_semantic_frame(name: :motion, domain: :physics)[:frame_id] }

    it 'adds a slot to a known frame' do
      result = client.define_frame_slot(frame_id: frame_id, name: :mover)
      expect(result[:defined]).to be true
      expect(result[:slot_name]).to eq(:mover)
    end

    it 'returns not found for unknown frame' do
      result = client.define_frame_slot(frame_id: 'bogus', name: :mover)
      expect(result[:defined]).to be false
      expect(result[:reason]).to eq(:frame_not_found)
    end
  end

  describe '#fill_frame_slot' do
    let(:frame_id) do
      id = client.create_semantic_frame(name: :motion, domain: :physics)[:frame_id]
      client.define_frame_slot(frame_id: id, name: :mover)
      id
    end

    it 'fills an existing slot' do
      result = client.fill_frame_slot(frame_id: frame_id, slot_name: :mover, filler: 'the car')
      expect(result[:filled]).to be true
      expect(result[:filler]).to eq('the car')
    end

    it 'returns error for unknown slot' do
      result = client.fill_frame_slot(frame_id: frame_id, slot_name: :nonexistent, filler: 'x')
      expect(result[:filled]).to be false
    end
  end

  describe '#instantiate_semantic_frame' do
    let(:frame_id) do
      id = client.create_semantic_frame(name: :motion, domain: :physics)[:frame_id]
      client.define_frame_slot(frame_id: id, name: :mover)
      client.fill_frame_slot(frame_id: id, slot_name: :mover, filler: 'rocket')
      id
    end

    it 'creates an instance snapshot' do
      result = client.instantiate_semantic_frame(frame_id: frame_id, context: 'test context')
      expect(result[:instantiated]).to be true
      expect(result[:instance_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:filled_count]).to eq(1)
    end

    it 'returns error for unknown frame' do
      result = client.instantiate_semantic_frame(frame_id: 'bogus', context: 'x')
      expect(result[:instantiated]).to be false
    end
  end

  describe '#add_frame_relation' do
    let(:frame_id)  { client.create_semantic_frame(name: :transfer,  domain: :commerce)[:frame_id] }
    let(:target_id) { client.create_semantic_frame(name: :payment,   domain: :commerce)[:frame_id] }

    it 'adds a valid frame relation' do
      result = client.add_frame_relation(
        frame_id: frame_id, relation: :has_subframe, target_frame_id: target_id
      )
      expect(result[:added]).to be true
    end

    it 'rejects an invalid relation' do
      result = client.add_frame_relation(
        frame_id: frame_id, relation: :nonsense, target_frame_id: target_id
      )
      expect(result[:added]).to be false
    end
  end

  describe '#activate_semantic_frame' do
    let(:frame_id) { client.create_semantic_frame(name: :competition, domain: :sports)[:frame_id] }

    it 'activates the frame' do
      result = client.activate_semantic_frame(frame_id: frame_id)
      expect(result[:activated]).to be true
    end

    it 'returns error for unknown frame' do
      result = client.activate_semantic_frame(frame_id: 'bogus')
      expect(result[:activated]).to be false
    end
  end

  describe '#active_frames_report' do
    it 'returns list of active frames' do
      id = client.create_semantic_frame(name: :competition, domain: :sports)[:frame_id]
      4.times { client.activate_semantic_frame(frame_id: id) }
      result = client.active_frames_report
      expect(result).to have_key(:frames)
      expect(result).to have_key(:count)
    end
  end

  describe '#related_frames_report' do
    let(:frame_id)  { client.create_semantic_frame(name: :buying, domain: :commerce)[:frame_id] }
    let(:target_id) { client.create_semantic_frame(name: :paying, domain: :commerce)[:frame_id] }

    before { client.add_frame_relation(frame_id: frame_id, relation: :has_subframe, target_frame_id: target_id) }

    it 'returns related frames' do
      result = client.related_frames_report(frame_id: frame_id)
      expect(result[:count]).to eq(1)
      expect(result[:frames].first[:id]).to eq(target_id)
    end
  end

  describe '#complete_frames_report' do
    it 'returns complete frames' do
      id = client.create_semantic_frame(name: :simple, domain: :test)[:frame_id]
      client.define_frame_slot(frame_id: id, name: :actor)
      client.fill_frame_slot(frame_id: id, slot_name: :actor, filler: 'someone')
      result = client.complete_frames_report
      expect(result[:count]).to be >= 1
    end
  end

  describe '#update_frame_semantics' do
    it 'runs decay and prune, returning updated status' do
      result = client.update_frame_semantics
      expect(result[:updated]).to be true
      expect(result[:stats]).to have_key(:frame_count)
    end
  end

  describe '#frame_semantics_stats' do
    it 'returns engine stats' do
      client.create_semantic_frame(name: :motion, domain: :physics)
      result = client.frame_semantics_stats
      expect(result[:frame_count]).to be >= 1
      expect(result).to have_key(:domains)
    end
  end
end
