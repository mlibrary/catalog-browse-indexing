# frozen_string_literal: true

# WHAT? Defining a global function? Yup.
#
# "Pretty print" a number into an underscore-delimited numeric string,
# right-space-padded out to the specified width (default 0 indicating
# "no padding") and with the specified number of digits to the right
# of the decimal point (default again 0, meaning no decimal point at all)
#
# Example: ppnum(10111) => "10_111"
#          ppnum(1234.56) => 1_235
#          ppnum(10111.3656, 10, 1) => "  10_111.4"
#
# No attempt is made to deal gracefully with numbers that overrun the
# specified width
# @param [Numeric] num the number to format
# @param [Integer] width The width to target
# @param [Integer] decimals Number of decimal places to show
# @return [String] The formatted number
def ppnum(num, width = 0, decimals = 0)
  num = num.round(decimals)
  dec_str = if decimals.zero?
              ""
            else
              ".#{format("%.#{decimals}f", num).split(".").last}"
            end
  numstr = num.floor.to_s.reverse.split(/(...)/)
              .reject(&:empty?)
              .map(&:reverse)
              .reverse
              .join("_") + dec_str
  if width.zero?
    numstr
  else
    format "%#{width}s", numstr
  end
end
