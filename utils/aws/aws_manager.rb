require 'aws-sdk'
require_relative 's3_manager'
require 'logger'

module AWSManager

  # AWS Connection
  aws_config = {access_key_id: "AKIAJTPGKC25LGKJUCTA", secret_access_key: "GAmrvii4bMbk5NGR8GiLSmHKbEUfCdp43uWi1ECv"}
  AWS.config(aws_config)


  # AWSManager logs information about its progress.
  # Jack in your own logger through this method if you wish to.
  #
  # @param [Logger] log your own logger
  # @return [Logger] the logger you set
  def self.logger=(log)
    @logger = log
  end

  # Get AWSManager logger.
  #
  # @return [Logger]
  def self.logger
    return @logger if @logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    @logger = logger
  end

end