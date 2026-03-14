# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module FrameSemantics
      module Helpers
        class Frame
          attr_reader :id, :name, :domain, :slots, :relations, :activation, :activation_count, :created_at

          def initialize(name:, domain:)
            @id               = SecureRandom.uuid
            @name             = name
            @domain           = domain
            @slots            = {}
            @relations        = []
            @activation       = DEFAULT_ACTIVATION
            @activation_count = 0
            @created_at       = Time.now.utc
          end

          def add_slot(name:, slot_type: :core, required: true)
            @slots[name] = { type: slot_type, filler: nil, required: required }
            self
          end

          def fill_slot(name:, filler:)
            return false unless @slots.key?(name)

            @slots[name][:filler] = filler
            @activation = [@activation + SLOT_FILL_BOOST, 1.0].min
            true
          end

          def clear_slot(name:)
            return false unless @slots.key?(name)

            @slots[name][:filler] = nil
            true
          end

          def core_slots
            @slots.select { |_k, v| v[:type] == :core }
          end

          def filled_slots
            @slots.reject { |_k, v| v[:filler].nil? }
          end

          def completion_ratio
            cs = core_slots
            return 0.0 if cs.empty?

            filled_core = cs.count { |_k, v| !v[:filler].nil? }
            filled_core.to_f / cs.size
          end

          def complete?
            completion_ratio >= COMPLETION_THRESHOLD
          end

          def activate!
            @activation = [@activation + ACTIVATION_BOOST, 1.0].min
            @activation_count += 1
            self
          end

          def decay!
            @activation = [@activation - ACTIVATION_DECAY, 0.0].max
            self
          end

          def activation_label
            ACTIVATION_LABELS.each do |range, label|
              return label if range.cover?(@activation)
            end
            :inactive
          end

          def add_relation(relation:, target_frame_id:)
            @relations << { relation: relation, target_frame_id: target_frame_id }
            self
          end

          def to_h
            {
              id:               @id,
              name:             @name,
              domain:           @domain,
              slots:            @slots,
              relations:        @relations,
              activation:       @activation,
              activation_label: activation_label,
              activation_count: @activation_count,
              completion_ratio: completion_ratio,
              complete:         complete?,
              created_at:       @created_at
            }
          end
        end
      end
    end
  end
end
