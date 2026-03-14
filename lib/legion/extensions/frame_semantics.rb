# frozen_string_literal: true

require 'legion/extensions/frame_semantics/version'
require 'legion/extensions/frame_semantics/helpers/constants'
require 'legion/extensions/frame_semantics/helpers/frame'
require 'legion/extensions/frame_semantics/helpers/frame_instance'
require 'legion/extensions/frame_semantics/helpers/frame_engine'
require 'legion/extensions/frame_semantics/runners/frame_semantics'
require 'legion/extensions/frame_semantics/helpers/client'

module Legion
  module Extensions
    module FrameSemantics
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
