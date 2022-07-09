# frozen_string_literal: true

require 'pry'
require 'lockfile'

load 'lib/logger.rb'
logger = Logger.new(print_to_screen: true)

load 'lib/database.rb'
Database.logger = logger
database = Database.new

load 'lib/json_object.rb'
load 'lib/check.rb'

JsonObject.database = database
JsonObject.logger = logger

begin
  binding.pry
ensure
  database.deinitalize
end
