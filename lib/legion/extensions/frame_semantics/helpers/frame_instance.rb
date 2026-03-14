# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module FrameSemantics
      module Helpers
        class FrameInstance
          attr_reader :id, :frame_id, :frame_name, :slot_fillers, :context, :confidence, :created_at

          def initialize(frame_id:, frame_name:, slot_fillers:, context:, confidence: 0.7)
            @id           = SecureRandom.uuid
            @frame_id     = frame_id
            @frame_name   = frame_name
            @slot_fillers = slot_fillers.dup
            @context      = context
            @confidence   = confidence
            @created_at   = Time.now.utc
          end

          def complete?
            filled_count.positive?
          end

          def filled_count
            @slot_fillers.count { |_k, v| !v.nil? }
          end

          def to_h
            {
              id:           @id,
              frame_id:     @frame_id,
              frame_name:   @frame_name,
              slot_fillers: @slot_fillers,
              context:      @context,
              confidence:   @confidence,
              filled_count: filled_count,
              complete:     complete?,
              created_at:   @created_at
            }
          end
        end
      end
    end
  end
end
