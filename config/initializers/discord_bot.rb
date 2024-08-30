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
    token = Rails.application.credentials.discord&.bot&.token
  end
end

DiscordBot.init
