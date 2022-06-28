# frozen_string_literal: true

settings do |s|
  store 'reader_class_name', 'Traject::LineReader'
end

each_record do |rec, context|
  context.output_hash = JSON.parse(rec)
  context.skip! if context.output_hash["type"] == "deprecated"
end

to_field("browse_field") do |rec, acc|
  acc << "naf"
end



