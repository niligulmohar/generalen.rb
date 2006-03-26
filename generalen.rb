#! /usr/bin/env ruby

require 'generalen/state'
require 'generalen/game'
require 'generalen/person'
require 'util/backup'
require 'util/prefix_words_matches'
require 'util/random'
require 'kombot'
require 'logger'
begin
  require 'readline'
  def read(prompt)
    Readline.readline(prompt, true)
  end
rescue LoadError => e
  def read(prompt)
    print(prompt)
    return gets
  end
end

class Generalen < KomBot
  def initialize(params = {})
    super(params.merge({ :unix_user => 'generalen',
                         :client_name => 'generalen.rb',
                         :client_version => '0.1.0',
                         :periodic_timeout => 10 }))
  end

  def async_send_message(msg, c)
    if msg.recipient == @params[:person]
      if msg.sender == @params[:person]
        $logger.debug('pong!')
      end
      $logger.info 'send_message %s: %s' % [ c.conf_name(msg.sender), msg.message ]
      Thread.new do
        $state.with_person(msg.sender) do |p|
          if not p
            p = $state.store[:people][msg.sender] = ::Person::KomPerson.new(msg.sender)
          end
          begin
            p.command(msg.message)
          rescue Exception => e
            puts e
            puts e.backtrace
          end
          p.flush
        end
        $logger.debug "send_message %s done" % [ c.conf_name(msg.sender), msg.message ]
      end
    end
  end

  def async_login(msg, c)
    $logger.info "login %s" % [c.conf_name(msg.person_no)]
    Thread.new do
      $state.with_person(msg.person_no) do |p|
        p.flush if p
      end
      $logger.debug "login %s done" % [c.conf_name(msg.person_no)]
    end
  end

  def periodic
    send_message(@params[:person], 'ping!')
    $logger.info('ping!')
  end
end


######################################################################

$KOM_SETTINGS = ({ :server => 'kom.lysator.liu.se',
                   :person => 12668,
                   :password => '64llob' })
STATE_FILE_NAME = 'GENERALEN.STATE'
LOG_FILE_NAME = 'GENERALEN.LOG'

$logger = Logger.new(File.new(LOG_FILE_NAME, 'a+'), 10, 1024**2)
$logger.info('started')

Backup::with_rotation(STATE_FILE_NAME)
$state = State.new(STATE_FILE_NAME, Random::Source.new)
$state.register_person(:Test, Person::TestPerson, 'Test')
$state.register_person(:Ap, Person::TestPerson, 'Ap')


# Thread.abort_on_exception = true

begin
  kom_thread = Thread.new do
    begin
      $kombot = Generalen.new($KOM_SETTINGS)
      $kombot.run
    rescue Interrupt
    rescue Exception => e
      puts e
      puts e.backtrace
    end
  end

  timeout_thread = Thread.new do
    loop do #while not $shutdown
      sleep(10)
      begin
        $state.with_person(:admin) do |p|
          $state.running_games.each do |g|
            if $state.request(:person => p, :game => g, :type => :timeout_poll)
              g.people.each do |p2|
                p2.flush
              end
            end
          end
        end
      rescue Exception => e
        puts e
        puts e.backtrace
      end
    end
  end

  loop do
    begin
      cmd = read((if $kombot.running? then '-!-' else '---' end) + ' generalen> ')
      if not cmd
        puts
        break
      elsif not cmd.empty?
        if cmd =~ (/^:/)
          $state.with_person(:admin) do |p|
            puts eval(cmd[1..-1])
            #p.command(cmd[1..-1])
            #p.flush
          end
        elsif cmd =~ (/^;/)
          $state.with_person(:Ap) do |p|
            p.command(cmd[1..-1])
            p.flush
          end
        else
          $state.with_person(:admin) do |admin|
            admin.command(cmd)
            admin.flush
          end
        end
      end
    rescue Exception => e
      puts e
      puts e.backtrace
    end
  end
  $shutdown = true
  timeout_thread.raise(Interrupt.new)
  kom_thread.raise(Interrupt.new)
  timeout_thread.join
  kom_thread.join
rescue Interrupt
  puts
end