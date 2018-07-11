#! /usr/bin/env ruby
# coding: utf-8
#--
# Copyright (c) Nicklas Lindgren 2016
# Det här programmet distribueras under villkoren i GPL v2.
#++

require_relative 'generalen/state'
require_relative 'generalen/game'
require_relative 'generalen/person'
require_relative 'util/backup'
require_relative 'util/prefix_words_matches'
require_relative 'util/random'
require 'logger'

require 'slack-ruby-client'


######################################################################

class SlackPerson < Person::TextInterfacePerson
  def initialize(user, channel)
    @user = user
    @channel = channel
    super()
  end
  def flush
    begin
      unless messages.empty?
        acc = []
        messages.each do |message|
          if message.respond_to? :attachments
            unless acc.empty?
              send_message(acc.join("\n\n"))
            end
            send_message(message)
          else
            acc << message
          end
        end
        unless acc.empty?
          send_message(acc.join("\n\n"))
        end
      end
      @map_message = nil
      @messages.clear
    end
  end
  def name
    "<@#{@user}>"
  end
  private
  def send_message(message)
    if message.respond_to? :attachments
      text = message.text
      attachments = message.attachments
    else
      text = message
      attachments = nil
    end
    $logger.debug("Meddelande till %s:\n%s" % [name, text])
    if text
      text = "```#{text.gsub(' ', ' ')}```"
    end
    $slack.web_client.chat_postMessage as_user: true, channel: @channel, text: text, attachments: attachments
  end
end

######################################################################

STATE_FILE_NAME = 'GENERALEN.STATE'
LOG_FILE_NAME = 'GENERALEN.LOG'

log_file = File.new(LOG_FILE_NAME, 'a+')
log_file.sync = true

$logger = Logger.new(log_file, 10, 1024**2)
$logger.info('started')
$logger.level = 1

Backup::with_rotation(STATE_FILE_NAME)
$state = State.new(STATE_FILE_NAME, Randomness::Source.new)
$state.startup

$settings = {
  :admin => ENV['SLACK_GENERALEN_ADMIN'] || '<@U0LHCLT0T>'
}

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  config.logger = $logger
end

$slack = Slack::RealTime::Client.new

$slack.on :message do |data|
  $logger.info 'send_message %s: %s' % [ data, data.text ]
  if data.user != $slack.self.id
    $state.with_person(data.user) do |p|
      if not p
        p = $state.store[:people][data.user] = SlackPerson.new(data.user, data.channel)
      end
      begin
        p.command(data.text)
      rescue Exception => e
        puts e
        puts e.backtrace
      end
      p.flush
    end
  end
  $logger.debug "send_message %s done" % [ data.user, data.text ]
end

$slack.start!
