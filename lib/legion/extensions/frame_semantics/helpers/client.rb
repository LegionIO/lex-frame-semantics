# frozen_string_literal: true

module Legion
  module Extensions
    module FrameSemantics
      module Helpers
        class Client
          include Runners::FrameSemantics

          private

          def engine
            @engine ||= FrameEngine.new
          end
        end
      end
    end
  end
end
