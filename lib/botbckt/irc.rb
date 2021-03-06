module Botbckt #:nodoc:
  
  # An EventMachine-based IRC client. See IRC.connect to get started.
  #
  class IRC < EventMachine::Connection
    include EventMachine::Protocols::LineText2
    
    attr_accessor :config
    cattr_accessor :connection
    
    # Instantiate a new IRC connection.
    #
    # ==== Parameters
    # options<Hash{Symbol => String,Integer}>
    #
    # ==== Options (options)
    # :user<String>:: The username this instance should use. Required.
    # :password<String>:: A password to send to the Nickserv. Optional.
    # :server<String>:: The FQDN of the IRC server. Required.
    # :port<~to_i>:: The port number of the IRC server. Required.
    # :channels<Array[String]>:: An array of channels to join. Channel names should *not* include the '#' prefix. Required.
    #
    def self.connect(options)
      self.connection = EM.connect(options[:server], options[:port].to_i, self, options)
    end
    
    # Use IRC.connect; this method is not for you.
    #
    #--
    # TODO: Ensure options[:channels] is always an Array
    #++
    def initialize(options) #:nodoc:
      self.config = OpenStruct.new(options)
    end
    
    # ==== Parameters
    # msg<String>:: A message to send to the channel. Required.
    # channel<String>:: The channel to send the message. Required.
    #
    def say(msg, channel)
      msg.split("\n").each do |msg|
        command "PRIVMSG", "##{channel}", ":#{msg}"
      end
    end
    
    def post_init #:nodoc:
      command "USER", [config.user]*4
      command "NICK", config.user
      command("NickServ IDENTIFY", config.user, config.password) if config.password
      config.channels.each { |channel| command("JOIN", "##{ channel }")  } if config.channels
    end

    def receive_line(line) #:nodoc:
      case line
      when /^PING (.*)/:
        command('PONG', $1)
      when /^:(\S+) PRIVMSG #(.*) :(~|#{Regexp.escape config.user}: )(\w+)( .*)?$/:
        # args are optional - not all commands need/support them
        args = [$1, $2]
        args << $5.squish if $5
        
         # run args: command, sender, channel, optional args
        self.config.bot.run($4, *args)
      else
        log line
      end
    end

    def unbind #:nodoc:
      EM.add_timer(3) do
        reconnect(config.server, config.port)
        post_init
      end
    end
    
    private

    def log(msg, level = Botbckt::Bot::INFO) #:nodoc:
      self.config.bot.log msg, level
    end
    
    def command(*cmd) #:nodoc:
      line = "#{ cmd.flatten.join(' ') }\r\n"
      send_data line
      log line
    end
    
  end
  
end
