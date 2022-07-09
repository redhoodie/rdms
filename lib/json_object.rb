# frozen_string_literal: true

require 'securerandom'

# An ActiveRecord like object.
class JsonObject
  attr_reader :attributes

  @@database = nil
  @@logger = nil
  @@default_attributes = {}

  def initialize(attributes = {})
    @@logger.log("JsonObject::#{__method__}(#{self.class.name}, #{attributes[:id]})", :debug)

    @attributes = @@default_attributes.merge(attributes)
    @attributes[:id] ||= SecureRandom.uuid

    super()
  end

  def respond_to_missing?(method_name, include_private = false)
    self.attributes.key?(method_name) || super
  end

  def method_missing(method_name, *arguments, &_block)
    method_name_string = method_name.to_s
    if method_name_string[-1..] == '='
      method_name = method_name_string[0...-1].to_sym
      value = arguments.first

      self.attributes[method_name] = value
      @@database.notify(self)
    end

    return self.attributes[method_name] if self.attributes&.key?(method_name)

    super
  end

  def table_name
    self.class.table_name
  end

  def self.table_name
    "#{name.downcase}s".to_sym
  end

  def self.find(id)
    @@logger.log("JsonObject::#{__method__}(#{table_name}, #{id})", :debug)

    @@database.find(table_name, id)
  end

  def self.all
    @@logger.log("JsonObject::#{__method__}(#{table_name})", :debug)

    objects = @@database.all(table_name) || []

    objects.collect { |attributes| new(attributes) }
  end

  # Class variable setters
  def self.default_attributes=(default_attributes = {})
    @@default_attributes = default_attributes
  end

  def self.database=(database)
    @@database = database
  end

  def self.logger=(logger)
    @@logger = logger
  end
end
