require 'kom'

class KomBot
  include Kom

  def initialize(params = {})
    @params = {
      :unix_user => 'kom.rb',
      :port => 4894,
      :client_name => 'KomBot.rb',
      :client_version => '0.1.0',
      :invisible => 1 }.merge(params)
  end
  def run
    @conn = CachedConnection.new(@params[:server],
                                 @params[:port],
                                 @params[:unix_user])
    ReqLogin.new(@conn,
                 @params[:person],
                 @params[:password],
                 @params[:invisible]).response
    ReqSetClientVersion.new(@conn,
                            @params[:client_name],
                            @params[:client_version])

    async_callbacks = []
    methods.each do |m|
      begin
        if Kom.const_defined? m.upcase
          async = Kom.const_get(m.upcase)
          @conn.add_async_handler(async, method(m))
          async_callbacks << async
        end
      rescue NameError
      end
    end
    ReqAcceptAsync.new(@conn, async_callbacks).response

    loop do
      data = select([@conn.socket], [], [], @params[:periodic_timeout])
      if data
        @conn.parse_present_data()
      else
        periodic
      end
    end
  end

  def send_message(person, msg)
    ReqSendMessage.new(@conn, person, msg).response
  end

  def conf_name(person)
    @conn.conf_name(person)
  end

  def running?
    @conn
  end

  private

  def periodic
  end
end
