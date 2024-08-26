Running locally:
1. install recommended ruby version from .ruby-version file, for example: `asdf install ruby 3.3.4`
2. install dependencies, for example: `bundle install --jobs=4`
3. get correct `config/master.key`
4. run bot via `bundle exec rake blame_ai:run_bot`
5. install bot to any Discord server via native UI by navigating to `https://discord.com/oauth2/authorize?&client_id=1273661622887383181&scope=bot`


Commands available:
1. Message commands (type in channel as a message)
  - `!ping` - ping bot to see if it answers
  - `!show_invite` - bot responds with invite link for itself, handy to share with someone while bot is private
  - `!register_app` - instruct bot to register application commands
  - `!destroy_app` - instruct bot to remove application commands from the server

2. Application commands (type `/` to see list of all commands on the server)
  - `/noop` - responds back without doing anything
  - `/pr_title` - given required pr_url arg - fetches it and responds with the PR title.
