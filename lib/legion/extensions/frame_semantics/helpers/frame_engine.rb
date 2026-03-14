# frozen_string_literal: true

module Legion
  module Extensions
    module FrameSemantics
      module Helpers
        class FrameEngine
          def initialize
            @frames    = {}
            @instances = []
          end

          def create_frame(name:, domain:, slots: {})
            frame = Frame.new(name: name, domain: domain)
            slots.each do |slot_name, opts|
              frame.add_slot(
                name:      slot_name,
                slot_type: opts.fetch(:type, :core),
                required:  opts.fetch(:required, true)
              )
            end
            prune_frames_if_full
            @frames[frame.id] = frame
            frame
          end

          def define_slot(frame_id:, name:, slot_type: :core, required: true)
            frame = @frames[frame_id]
            return nil unless frame

            frame.add_slot(name: name, slot_type: slot_type, required: required)
            frame
          end

          def fill_slot(frame_id:, slot_name:, filler:)
            frame = @frames[frame_id]
            return false unless frame

            result = frame.fill_slot(name: slot_name, filler: filler)
            frame.activate! if result
            result
          end

          def instantiate_frame(frame_id:, context:, confidence: 0.7)
            frame = @frames[frame_id]
            return nil unless frame

            fillers = frame.slots.transform_values { |v| v[:filler] }
            instance = FrameInstance.new(
              frame_id:     frame_id,
              frame_name:   frame.name,
              slot_fillers: fillers,
              context:      context,
              confidence:   confidence
            )
            @instances << instance
            @instances.shift while @instances.size > MAX_INSTANCES
            instance
          end

          def add_frame_relation(frame_id:, relation:, target_frame_id:)
            frame = @frames[frame_id]
            return false unless frame
            return false unless FRAME_RELATIONS.include?(relation)

            frame.add_relation(relation: relation, target_frame_id: target_frame_id)
            true
          end

          def activate_frame(frame_id:)
            frame = @frames[frame_id]
            return false unless frame

            frame.activate!
            true
          end

          def active_frames
            @frames.values.select { |f| f.activation > 0.5 }
          end

          def frames_by_domain(domain:)
            @frames.values.select { |f| f.domain == domain }
          end

          def related_frames(frame_id:)
            frame = @frames[frame_id]
            return [] unless frame

            frame.relations.filter_map { |rel| @frames[rel[:target_frame_id]] }
          end

          def most_activated(limit: 5)
            @frames.values.sort_by { |f| -f.activation }.first(limit)
          end

          def instances_for_frame(frame_id:)
            @instances.select { |i| i.frame_id == frame_id }
          end

          def complete_frames
            @frames.values.select(&:complete?)
          end

          def decay_all
            @frames.each_value(&:decay!)
          end

          def prune_inactive
            @frames.reject! { |_id, f| f.activation <= 0.05 }
          end

          def to_h
            {
              frame_count:    @frames.size,
              instance_count: @instances.size,
              active_count:   active_frames.size,
              complete_count: complete_frames.size,
              domains:        @frames.values.map(&:domain).uniq.sort
            }
          end

          private

          def prune_frames_if_full
            return unless @frames.size >= MAX_FRAMES

            oldest = @frames.values.min_by(&:activation)
            @frames.delete(oldest.id) if oldest
          end
        end
      end
    end
  end
end
