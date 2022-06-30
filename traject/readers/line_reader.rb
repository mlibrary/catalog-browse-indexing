# frozen_string_literal: true

# Just yield lines of the file one at a time without the
# trailing newline

require "zinzout"

# Read newline-delimited JSON file, where each line is a marc-in-json string.
# UTF-8 encoding is required.

class Traject::LineReader
  include Enumerable

  def initialize(input_stream, settings)
    @settings = settings
    @input_stream = input_stream
    if input_stream.respond_to?(:path)
      @input_stream = Zinzout.zin(input_stream.path)
    end
  end

  def logger
    @logger ||= (@settings[:logger] || Yell.new(STDERR, level: "gt.fatal")) # null logger)
  end

  def each
    unless block_given?
      return enum_for(:each)
    end

    @input_stream.each_with_index do |line, i|
      line.chomp!
      yield line
    rescue Exception => e
      logger.error("Problem with JSON record on line #{i}: #{e.message}")
    end
  end
end
