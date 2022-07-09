# frozen_string_literal: true

# Database like JSON file class

require 'lockfile'
require 'json'

# A Database hashlike object
class Database < Hash
  DATABASE_FILE = './db/database.json'

  @@logger = nil
  @dirty = false

  def initialize
    @data = {}
    read_data
    super
  end

  def notify(object)
    @@logger.log("Database::#{__method__}(#{object.table_name}, #{object.id})", :debug)

    save(object)
  end

  def deinitalize
    write_data
  end

  def all(table_name)
    self[table_name.to_sym]&.values
  end

  def find(table_name, id)
    self.dig(table_name.to_sym, id.to_sym)
  end

  def self.logger=(logger)
    @@logger = logger
  end

  private

  def save(object)
    table_name = object.table_name
    id = object.id.to_sym
    return if table_name.nil? || id.nil?

    @dirty = true

    self[table_name] ||= {}
    self[table_name][id] = object.attributes
  end

  # Load data from DATABASE_FILE
  def read_data
    @@logger.debug("Database::#{__method__}")
    return unless File.exist?(DATABASE_FILE)

    begin
      data = JSON.parse(File.read(DATABASE_FILE), symbolize_names: true)

      data.each { |k, v| self[k] = v }
    rescue JSON::ParserError => e
      @@logger.error("Database::#{__method__}")
      @@logger.error(e.full_message)

      # Database is corrupt, backup the database
      FileUtils.copy(DATABASE_FILE, "#{DATABASE_FILE}.broken")
    end
  end

  # Save out data from DATABASE_FILE
  def write_data
    @@logger.debug("Database::#{__method__}: dirty:\t#{@dirty ? 'true' : 'false'}")
    return unless @dirty

    lockfile = Lockfile.new "#{DATABASE_FILE}.lock"
    begin
      lockfile.lock
      File.write(DATABASE_FILE, JSON.pretty_generate(self))

      @@logger.debug("Database::#{__method__}: written")
    ensure
      lockfile.unlock
    end
  end
end
