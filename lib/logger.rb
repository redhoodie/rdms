# frozen_string_literal: true

# Handle logging
class Logger
  LOGGER_FILE = './log/logger.log'

  LOG_LEVELS = [
    :debug,
    :info,
    :warn,
    :error
  ]

  DEFAULT_OPTIONS = {
    print_to_screen: false,
    level: :debug
  }

  def initialize(options = {})
    @options = DEFAULT_OPTIONS.merge(options)
    rotate
  end

  LOG_LEVELS.each do |level|
    define_method(level) do |msg|
      log(msg, level)
    end
  end

  def log(msg, level = :info)
    return unless log?(level)

    message = "#{Time.now.utc}\t#{level}\t#{msg}"

    print_to_stdout(message) if @options[:print_to_screen]
    print_to_file(message)
  end

  private

  def print_to_file(message)
    open(LOGGER_FILE, 'a') do |f|
      f.puts message
    end
  end

  def print_to_stdout(message)
    puts message
  end

  def log?(message_level)
    config_level_i = LOG_LEVELS.find_index(@options[:level])
    message_level_i = LOG_LEVELS.find_index(message_level)

    message_level_i >= config_level_i
  end

  def rotate
    log_file_days_old = (Time.now - File.stat(LOGGER_FILE).mtime).to_i / 86_400.0
    return if log_file_days_old < 1.0

    log_path = File.dirname(LOGGER_FILE)
    log_file_name = File.basename(LOGGER_FILE)
    rotated_file_name = "#{log_path}/#{Time.now.utc}-#{log_file_name}"
    FileUtils.move(LOGGER_FILE, rotated_file_name)
    `gzip '#{rotated_file_name}'`
  end
end
