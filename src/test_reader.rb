# coding: utf-8
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))

require 'yaml'
# require 'active_support'
# require 'active_support/core_ext'

# Encoding.default_external = 'utf-8'
# Encoding.default_internal = 'utf-8'

class TestReader
  attr_reader :scenarios
  attr_reader :sequences
  def initialize(path)
    @path = path
    read_yaml(@path)
  end

  def symbolize(obj)
    return obj.inject({}){|memo,(k,v)| memo[k.to_sym] =  symbolize(v); memo} if obj.is_a? Hash
    return obj.inject([]){|memo,v    | memo           << symbolize(v); memo} if obj.is_a? Array
    return obj
  end
  
  # yamlファイル読込
  def read_yaml(path)
    @scenarios = Hash.new
    @sequences = Hash.new
    Dir.glob("#{path}/**/*.yml") do |file|
      puts "reading... #{file}"
      body = File.read( file, external_encoding: 'utf-8')
      # body = HashWithIndifferentAccess.new(YAML.load(body))
      body = symbolize(YAML.load(body))
      raise "ERROR: not found :content_type" unless body.has_key? :content_type
      raise "ERROR: not found :contents" unless body.has_key? :contents
      contents = body[:contents]
      raise "ERROR: not found :name" unless contents.has_key? :name
      if body[:content_type] == 'screen_test_scenario'
        raise "ERROR: multiple scenario name: #{contents[:name]}" if @scenarios.has_key? contents[:name].to_sym
        raise "ERROR: not found :config" unless contents.has_key? :config
        raise "ERROR: not found :sequences" unless contents.has_key? :sequences
        @scenarios[contents[:name].to_sym] = contents
      elsif body[:content_type] == 'screen_test_sequence'
        raise "ERROR: multiple sequence name: #{contents[:name]}" if @sequences.has_key? contents[:name].to_sym
        raise "ERROR: not found :commands" unless contents.has_key? :commands
        @sequences[contents[:name].to_sym] = contents
      else
        raise "ERROR: unknown content_type: #{body[:content_type]}"
      end
    end
  end
end
