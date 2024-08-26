namespace :blame_ai do
  desc "Run dedicated Discord Bot"
  task run_bot: :environment do
    Discord::Bot.commands
  end
end
