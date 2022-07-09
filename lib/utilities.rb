# frozen_string_literal: true

# A utility module
module Utilities
  def hello
    puts "Running #{Check.all.count} checks..."
  end

  def results
    # Print results
    puts
    puts 'Results:'
    Check.all.each do |check|
      puts
      puts "Name:\t#{check.nice_name}"
      puts "Type:\t#{check.type}"
      puts "Host:\t#{check.host}"
      puts
      if check.last_run_success
        puts 'Success!'
      else
        puts "Failure.\t(#{check.last_run_error})"
      end
      puts
      puts '###'
    end
    puts
  end
end
