# frozen_string_literal: true

module Legion
  module Extensions
    module FrameSemantics
      module Runners
        module FrameSemantics
          def create_semantic_frame(name:, domain:, **)
            frame = engine.create_frame(name: name, domain: domain)
            Legion::Logging.debug "[frame_semantics] created frame name=#{name} domain=#{domain} id=#{frame.id[0..7]}"
            { frame_id: frame.id, name: frame.name, domain: frame.domain, created: true }
          end

          def define_frame_slot(frame_id:, name:, slot_type: :core, required: true, **)
            frame = engine.define_slot(frame_id: frame_id, name: name, slot_type: slot_type, required: required)
            if frame
              Legion::Logging.debug "[frame_semantics] defined slot #{name} on frame #{frame_id[0..7]}"
              { defined: true, frame_id: frame_id, slot_name: name, slot_type: slot_type }
            else
              { defined: false, reason: :frame_not_found }
            end
          end

          def fill_frame_slot(frame_id:, slot_name:, filler:, **)
            result = engine.fill_slot(frame_id: frame_id, slot_name: slot_name, filler: filler)
            if result
              Legion::Logging.debug "[frame_semantics] filled slot #{slot_name} on frame #{frame_id[0..7]}"
              { filled: true, frame_id: frame_id, slot_name: slot_name, filler: filler }
            else
              { filled: false, reason: :slot_or_frame_not_found }
            end
          end

          def instantiate_semantic_frame(frame_id:, context:, confidence: 0.7, **)
            instance = engine.instantiate_frame(frame_id: frame_id, context: context, confidence: confidence)
            if instance
              Legion::Logging.debug "[frame_semantics] instantiated frame #{frame_id[0..7]} instance=#{instance.id[0..7]}"
              { instantiated: true, instance_id: instance.id, frame_id: frame_id, filled_count: instance.filled_count }
            else
              { instantiated: false, reason: :frame_not_found }
            end
          end

          def add_frame_relation(frame_id:, relation:, target_frame_id:, **)
            result = engine.add_frame_relation(frame_id: frame_id, relation: relation, target_frame_id: target_frame_id)
            if result
              Legion::Logging.debug "[frame_semantics] added relation #{relation} #{frame_id[0..7]}->#{target_frame_id[0..7]}"
              { added: true, frame_id: frame_id, relation: relation, target_frame_id: target_frame_id }
            else
              { added: false, reason: :invalid_frame_or_relation }
            end
          end

          def activate_semantic_frame(frame_id:, **)
            result = engine.activate_frame(frame_id: frame_id)
            if result
              Legion::Logging.debug "[frame_semantics] activated frame #{frame_id[0..7]}"
              { activated: true, frame_id: frame_id }
            else
              { activated: false, reason: :frame_not_found }
            end
          end

          def active_frames_report(**)
            frames = engine.active_frames
            Legion::Logging.debug "[frame_semantics] active_frames count=#{frames.size}"
            { frames: frames.map(&:to_h), count: frames.size }
          end

          def related_frames_report(frame_id:, **)
            frames = engine.related_frames(frame_id: frame_id)
            Legion::Logging.debug "[frame_semantics] related_frames frame=#{frame_id[0..7]} count=#{frames.size}"
            { frames: frames.map(&:to_h), count: frames.size }
          end

          def complete_frames_report(**)
            frames = engine.complete_frames
            Legion::Logging.debug "[frame_semantics] complete_frames count=#{frames.size}"
            { frames: frames.map(&:to_h), count: frames.size }
          end

          def update_frame_semantics(**)
            engine.decay_all
            engine.prune_inactive
            Legion::Logging.debug '[frame_semantics] decay_all + prune_inactive complete'
            { updated: true, stats: engine.to_h }
          end

          def frame_semantics_stats(**)
            engine.to_h
          end

          private

          def engine
            @engine ||= Helpers::FrameEngine.new
          end
        end
      end
    end
  end
end
