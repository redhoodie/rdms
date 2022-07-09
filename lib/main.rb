# frozen_string_literal: true

LOG_LEVEL = :debug
LOG_TO_SCREEN = true

require 'pry'
require 'concurrent'
require 'lockfile'

load 'lib/logger.rb'
logger = Logger.new(print_to_screen: LOG_TO_SCREEN, level: LOG_LEVEL)

load 'lib/database.rb'
Database.logger = logger
database = Database.new

load 'lib/json_object.rb'
load 'lib/check.rb'

JsonObject.database = database
JsonObject.logger = logger

load 'lib/utilities.rb'
include Utilities

begin
  hello

  pool = Concurrent::CachedThreadPool.new
  Check.all.each do |check|
    pool.post do
      check.run(:check)
      check.run(:commands)
      check.run(:check_if_failed)
    rescue StandardError => e
      logger.log(e.full_message, :error)
    end
  end

  pool.shutdown
  pool.wait_for_termination

  results
ensure
  database.deinitalize
end
