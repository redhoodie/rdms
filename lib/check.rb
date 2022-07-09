# frozen_string_literal: true

load 'lib/json_object.rb'

require 'net/ping'

# A Check model
class Check < JsonObject
  default_attributes = {
    name: nil,
    host: nil,
    type: nil,

    notify_email: nil,
    command_success: nil,
    command_failure: nil,

    check_failed_delay: 30,
    last_run_success: nil,
    last_run_at: nil
  }

  def nice_name
    name || "#{type} #{host}"
  end

  def run(stage = :check)
    # TODO: ...
    # - [ ] Checks
    #   - [x] ping host
    #   - [x] 2XX HTTP / HTTPS
    # - [ ] Notify
    # - [x] Run Command

    if stage == :check_if_failed && !last_run_success
      @@logger.debug("Check(#{id})::#{__method__}(#{stage})")

      unless check_failed_delay.nil?
        @@logger.debug("Check(#{id})::#{__method__}::sleep(#{check_failed_delay})")
        sleep(check_failed_delay)
      end
      stage == :check
    end

    run_check if stage == :check
    run_commands if stage == :commands

    last_run_success
  end

  private

  def run_check
    @@logger.debug("Check(#{id})::#{__method__}")

    self.last_run_error = nil

    success = send("check_#{type}")
    @@logger.debug("Check(#{id})::run_check: success:\t#{success}")

    success_changed = last_run_success != success
    @@logger.debug("Check(#{id})::run_check: success_changed:\t#{success_changed}")

    self.last_run_at = Time.now.utc
    self.last_run_success = success

    notify if success_changed

    success
  end

  def notify
    @@logger.debug("Check(#{id})::#{__method__}")
    # TODO: complete this function
  end

  def run_commands
    @@logger.debug("Check(#{id})::#{__method__}")

    success = last_run_success
    if success && !command_success.nil?
      run_commmand(command_success)
    elsif !success && !command_failure.nil?
      run_commmand(command_failure)
    end
  end

  def check_ping
    @@logger.debug("Check(#{id})::#{__method__}")

    ping = Net::Ping::External.new(host)
    result = ping.ping?

    exception = ping.exception&.downcase&.to_sym
    @@logger.info("Check(#{id})::#{__method__}: exception:\t#{exception}") unless exception.nil?

    @@logger.info("Check(#{id})::#{__method__}: result:\t#{result}")

    if result
      true
    else
      self.last_run_error = exception
      false
    end
  end

  def check_http
    @@logger.debug("Check(#{id})::#{__method__}")

    valid_exceptions = [:unauthorized, :'method not allowed']
    ping = Net::Ping::HTTP.new(host)

    result = ping.ping?

    exception = ping.exception&.downcase&.to_sym
    @@logger.info("Check(#{id})::#{__method__}: exception:\t#{exception}") unless exception.nil?

    result ||= valid_exceptions.include?(exception)

    @@logger.info("Check(#{id})::#{__method__}: result:\t#{result}")

    if result
      true
    else
      self.last_run_error = exception
      false
    end
  end

  def run_commmand(command)
    @@logger.debug("Check(#{id})::#{__method__}")
    @@logger.info("Check(#{id})::#{__method__}(#{command})")
    output = %x[ #{command} ]
    @@logger.info("Check(#{id})::#{__method__}(#{command})= #{output}")
  end
end
