if ENV["DISCORD_BOT_TOKEN"]
  module DiscordBot
    extend self

    def init
      @@bot = Discordrb::Bot.new(token:) if token
    end

    def bot
      @@bot || init
    end

    private

    def token
      @token ||= ENV["DISCORD_BOT_TOKEN"]
    end
  end

  DiscordBot.init
end
