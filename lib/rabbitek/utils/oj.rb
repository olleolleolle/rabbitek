# frozen_string_literal: true

module Rabbitek
  module Utils
    ##
    # Oj methods wrapper
    class Oj
      def self.dump(obj)
        ::Oj.dump(obj, mode: :compat)
      end

      def self.load(string)
        ::Oj.load(string, mode: :compat)
      end
    end
  end
end
