module Discord
  module Bot
    extend self

    def commands
      bot = DiscordBot.bot

      # type !ping in a channel to get a pong! response
      bot.message(content: "!ping") do |event|
        Discordrb::LOGGER.info("Received message command: #{event.message.content}")
        event.respond("pong!")
      end

      # type !show_invite in a channel to get the invite URL for the bot
      bot.message(content: "!show_invite") do |event|
        Discordrb::LOGGER.info("Received message command: #{event.message.content}")
        event.respond(event.bot.invite_url)
      end

      # type !register_app in a channel to register application commands
      bot.message(content: "!register_app") do |event|
        server_id = event.server.id
        bot.register_application_command(:noop, "No-op command", server_id:)
        bot.register_application_command(:pr_title, "Show PR title", server_id:) do |cmd|
          cmd.string("pr_url", "The URL of the PR", required: true)
        end
      end

      # type !destroy_app in a channel to destroy(unregister) application commands
      bot.message(content: "!destroy_app") do |event|
        server_id = event.server.id
        commands = bot.get_application_commands(server_id: server_id)

        commands.each do |command|
          bot.delete_application_command(command.id, server_id:)
          Discordrb::LOGGER.warn("Deleted command: #{command.name}")
        end
      end

      # type !noop in a channel to get a no-op response
      bot.application_command(:noop) do |event|
        Discordrb::LOGGER.info("Received application command: #{event.command_name}")
        event.respond(content: "No-op command received")
      end

      # type !pr_title in a channel to get the title of a PUBLIC PR
      bot.application_command(:pr_title) do |event|
        Discordrb::LOGGER.info("Received application command: #{event.command_name}")

        pr_url = event.options["pr_url"]
        pr_service = FetchGithubPullRequestData.new(pr_url)
        pr_metadata = pr_service.parse_pull_request_url
        pr_data = pr_service.fetch_pull_request_data(pr_metadata)

        event.respond(content: "The PR title is: #{pr_data[:title]}")
      rescue ArgumentError => e
        event.respond(content: e.message)
      end

      bot.run
    end
  end
end