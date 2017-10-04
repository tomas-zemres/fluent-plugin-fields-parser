require "logfmt"
require "fluent/plugin/output"

module Fluent::Plugin
  class OutputFieldsParser < Output
    Fluent::Plugin.register_output('fields_parser', self)

    helpers :event_emitter

    config_param :remove_tag_prefix,  :string, :default => nil
    config_param :add_tag_prefix,     :string, :default => nil
    config_param :parse_key,          :string, :default => 'message'
    config_param :fields_key,         :string, :default => nil
    config_param :pattern,            :string,
                 :default => %{([a-zA-Z_]\\w*)=((['"]).*?(\\3)|[\\w.@$%/+-]*)}
    config_param :strict_key_value,  :bool, :default => false

    def compiled_pattern
      @compiled_pattern ||= Regexp.new(pattern)
    end

    def process(tag, es)
      tag = update_tag(tag)
      es.each { |time, record|
        router.emit(tag, time, parse_fields(record))
      }
    end

    def update_tag(tag)
      if remove_tag_prefix
        if remove_tag_prefix == tag
          tag = ''
        elsif tag.to_s.start_with?(remove_tag_prefix+'.')
          tag = tag[remove_tag_prefix.length+1 .. -1]
        end
      end
      if add_tag_prefix
        tag = tag && tag.length > 0 ? "#{add_tag_prefix}.#{tag}" : add_tag_prefix
      end
      return tag
    end

    def parse_fields(record)
      source = record[parse_key].to_s
      target = fields_key ? (record[fields_key] ||= {}) : record

      if strict_key_value
        # Use logfmt to parse it (key=value)
        parsed = Logfmt.parse(source)
        target.merge!(parsed)
      else
        source.scan(compiled_pattern) do |match|
          (key, value, begining_quote, ending_quote) = match
          next if key.nil?
          next if target.has_key?(key)
          value = value.to_s
          from_pos = begining_quote.to_s.length
          to_pos = value.length - ending_quote.to_s.length - 1
          target[key] = value[from_pos..to_pos]
        end
      end

      return record
    end
  end
end
