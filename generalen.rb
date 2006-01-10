#! /usr/bin/env ruby

require 'generalen/state'
require 'generalen/game'
require 'generalen/person'
require 'util/prefix_words_matches'
require 'util/random'
require 'kombot'
require 'logger'
require 'readline'

class Generalen < KomBot
  def initialize(params = {})
    super(params.merge({ :unix_user => 'generalen',
                         :client_name => 'generalen.rb',
                         :client_version => '0.1.0',
                         :periodic_timeout => 10 }))
  end

  def async_send_message(msg, c)
    if msg.recipient == @params[:person]
      $logger.info "send_message %s: %s" % [ c.conf_name(msg.sender), msg.message ]
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
end


######################################################################

$logger = Logger.new(File.new('GENERALEN.LOG', 'a+'), 10, 1024**2)
$logger.info('started')
$state = State.new('GENERALEN.STATE', Random::Source.new)
$state.register_person(:Test, Person::TestPerson, 'Test')
$state.register_person(:Ap, Person::TestPerson, 'Ap')

Thread.abort_on_exception = true

begin
  kom_thread = Thread.new do
    begin
      $kombot = Generalen.new(:server => 'kom.lysator.liu.se',
                              :person => 12668,
                              :password => '64llob')
      $kombot.run
    rescue Exception => e
      puts e
      puts e.backtrace
    end
  end

  timeout_thread = Thread.new do
    loop do
      sleep(10)
      $state.with_person(:admin) do |p|
        $state.running_games.each do |g|
          if $state.request(:person => p, :game => g, :type => :timeout_poll)
            g.people.each do |p2|
              p2.flush
            end
          end
        end
      end
    end
  end

  loop do
    begin
      #cmd = Readline.readline('--- generalen> ', true)
      print('--- generalen> ')
      cmd = gets
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
  kom_thread.join
  timeout_thread.join
rescue Interrupt
  puts
end
