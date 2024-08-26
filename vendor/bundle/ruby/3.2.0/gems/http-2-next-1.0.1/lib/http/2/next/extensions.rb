# frozen_string_literal: true

module HTTP2Next
  module StringExtensions
    refine String do
      def read(n)
        return "".b if n == 0

        chunk = byteslice(0..n - 1)
        remaining = byteslice(n..-1)
        remaining ? replace(remaining) : clear
        chunk
      end

      def read_uint32
        read(4).unpack1("N")
      end

      def shift_byte
        read(1).ord
      end
    end
  end
end
