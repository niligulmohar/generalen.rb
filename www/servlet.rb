# coding: utf-8
#--
# Copyright (c) Nicklas Lindgren 2005-2007
# Det här programmet distribueras under villkoren i GPL v2.
#++

require 'webrick'

######################################################################

class Array
  def to_js
    '[' + collect{|e| e.to_js}.join(',') + ']'
  end
end

class String
  def to_js
    inspect
  end
end

class Integer
  def to_js
    to_s
  end
end

class Symbol
  def to_js
    to_s
  end
end

class TrueClass
  def to_js
    to_s
  end
end

class FalseClass
  def to_js
    to_s
  end
end

class Hash
  def to_js
    '{' + collect{|k, v| '%s:%s' % [k.to_js, v.to_js]}.join(',') + '}'
  end
end

######################################################################

module Servlet
  AJA_ROOT = '/aja/'
  class Session
    attr_reader :cookie, :conn, :thread
    attr_accessor :requests, :waiting
    @@sessions = {}
    @@shutdown = false
    def Session.[](cookie)
      @@sessions[cookie] || Session.new(cookie)
    end
    def Session.shutdown
      @@shutdown = true
      @@sessions.each do |k, v|
        v.post_request('a' => 'reset')
      end
    end

    def initialize(cookie = nil)
      @cookie = cookie || Session.new_session_cookie
      @@sessions[@cookie] = self
      @requests = 0
      @request_map = {}

      @message_mutex = Mutex.new
      @message_cond = ConditionVariable.new
      @messages = []
      @kom_mutex = Mutex.new
      @waiting = 0
      @thread = Thread.new do
        listen
      end
    end
    def post_request(params)
      @kom_mutex.synchronize do
        case params[:path]
        when 'reset'
          @stop = true
          catch (:done) do
            loop do
              @message_mutex.synchronize do
                throw :done if waiting == 0
                @message_cond.signal
              end
            end
          end
          @stop = false unless @@shutdown
          post_message(:async => 'info')
        end
      end
    end
    def post_message(message)
      @message_mutex.synchronize do
        @messages << message.to_js
        @message_cond.signal
      end
    end
    def wait_message
      @message_mutex.synchronize do
        self.waiting += 1
        while @messages.empty? and not @stop do
          @message_cond.wait(@message_mutex)
        end
        self.waiting -= 1
        return '' if @stop
        return @messages.pop
      end
    end

    private
    def listen
      while not @disconnect do
        data = select([@conn.socket], [], [], 10)
        if data
          @kom_mutex.synchronize do
            @conn.parse_present_data()
          end
        end
      end
    end
    def Session.new_session_cookie
      i = nil
      begin
        i = (rand()*(2**31)).to_i.to_s
      end while @@sessions.has_key?(i)
      i
    end
  end

  ######################################################################

  class GeneralenServlet < WEBrick::HTTPServlet::AbstractServlet
    def do_GET(request, response)
      s = session(request, response)
      p = params(request)
      if p[:path].empty?
        response.body = s.wait_message()
      else
        s.post_request(p)
        response.body = p.to_js
      end
      raise WEBrick::HTTPStatus::OK
    end

    private
    def params(request)
      params = {}
      (if request.body then request.body else request.query_string || '' end).chomp.split('&').each do |p|
        k, v = p.split('=').collect{|p| WEBrick::HTTPUtils::unescape_form(p)}
        params.update(k.to_sym => v)
      end
      params[:path] = request.path.sub(/^#{AJA_ROOT}/, '')
      return params
    end

    def session(request, response)
      if request.cookies.empty?
        session = Session.new
        cookie = WEBrick::Cookie.new('generalen', session.cookie)
        response.cookies << cookie
      else
        session = Session[request.cookies[0].value]
      end
      session.requests += 1
      session
    end
  end

  ######################################################################

  class << self
    def start()
      $servlet = WEBrick::HTTPServer.new(:Port => 4141, :DocumentRoot => 'www/public', :MimeTypes => WEBrick::HTTPUtils::DefaultMimeTypes.merge('xml' => 'text/xml;charset=UTF-8'), :DirectoryIndex => ['index.xml'])
      $servlet.mount(AJA_ROOT, GeneralenServlet)
      $servlet.start
    end
    def stop()
      $servlet.shutdown
      Session.shutdown
    end
  end
end
