# frozen_string_literal: true

module Legion
  module Extensions
    module FrameSemantics
      module Helpers
        SLOT_TYPES        = %i[core peripheral extra_thematic].freeze
        FRAME_RELATIONS   = %i[inherits_from is_inherited_by uses is_used_by subframe_of has_subframe].freeze
        ACTIVATION_LABELS = {
          (0.8..)     => :dominant,
          (0.6...0.8) => :active,
          (0.4...0.6) => :primed,
          (0.2...0.4) => :latent,
          (..0.2)     => :inactive
        }.freeze

        MAX_FRAMES         = 150
        MAX_INSTANCES      = 500
        MAX_HISTORY        = 500
        DEFAULT_ACTIVATION = 0.3
        ACTIVATION_BOOST   = 0.15
        ACTIVATION_DECAY   = 0.03
        SLOT_FILL_BOOST    = 0.1
        COMPLETION_THRESHOLD = 0.7
      end
    end
  end
end
