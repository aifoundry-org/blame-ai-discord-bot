module Discord
  module Bot
    extend self

    def allowed?(event)
      return false unless event.server&.id == ENV["DISCORD_SERVER_ID"].to_i
      return false unless event.channel&.id == ENV["DISCORD_CHANNEL_ID"].to_i

      true
    end

    def commands
      bot = DiscordBot.bot

      # type !ping in a channel to get a pong! response
      bot.message(content: "!ping") do |event|
        break unless allowed?(event)
        Discordrb::LOGGER.info("Received message command: #{event.message.content}")
        event.respond("pong!")
      end

      # type !show_invite in a channel to get the invite URL for the bot
      bot.message(content: "!show_invite") do |event|
        break unless allowed?(event)
        Discordrb::LOGGER.info("Received message command: #{event.message.content}")
        event.respond(event.bot.invite_url)
      end

      # type !register_app in a channel to register application commands
      bot.message(content: "!register_app") do |event|
        break unless allowed?(event)
        Discordrb::LOGGER.info("Received message command: #{event.message.content}")

        server_id = event.server.id
        bot.register_application_command(:noop, "No-op command", server_id:)
        bot.register_application_command(:pr_title, "Show PR title", server_id:) do |cmd|
          cmd.string("pr_url", "The URL of the PR", required: true)
        end
        bot.register_application_command(:blame, "Summarize a PR", server_id:) do |cmd|
          cmd.string("pr_url", "The URL of the PR", required: true)
        end
      end

      # type !destroy_app in a channel to destroy(unregister) application commands
      bot.message(content: "!destroy_app") do |event|
        break unless allowed?(event)
        Discordrb::LOGGER.info("Received message command: #{event.message.content}")

        server_id = event.server.id
        commands = bot.get_application_commands(server_id: server_id)

        commands.each do |command|
          bot.delete_application_command(command.id, server_id:)
          Discordrb::LOGGER.warn("Deleted command: #{command.name}")
        end
      end

      # type !noop in a channel to get a no-op response
      bot.application_command(:noop) do |event|
        break unless allowed?(event)
        Discordrb::LOGGER.info("Received application command: #{event.command_name}")
        event.respond(content: "No-op command received")
      end

      # type !pr_title in a channel to get the title of a PUBLIC PR
      bot.application_command(:pr_title) do |event|
        break unless allowed?(event)
        Discordrb::LOGGER.info("Received application command: #{event.command_name}")

        pr_url = event.options["pr_url"]
        pr_service = FetchGithubPullRequestData.new(pr_url)
        pr_metadata = pr_service.parse_pull_request_url
        pr_data = pr_service.fetch_pull_request_data(pr_metadata)

        event.respond(content: "The PR title is: #{pr_data[:title]}")
      rescue ArgumentError => e
        event.respond(content: e.message)
      end

      bot.application_command(:blame) do |event|
        break unless allowed?(event)
        Discordrb::LOGGER.info("Received application command: #{event.command_name}")

        # Defer the response to let Discord know we're processing the command
        event.defer

        Thread.new do
          begin
            pr_url = event.options["pr_url"]
            summary = Blame.new(pr_url).call

            event.edit_response(content: summary.gsub(%r{\bhttps?://[^\s<]+}, '<\0>'))
          rescue ArgumentError => e
            event.edit_response(content: e.message)
          end
        end
      end

      bot.run
    end
  end
end
