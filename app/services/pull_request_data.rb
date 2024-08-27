class PullRequestData
  def initialize(data)
    @data = data[:pull_request]
  end

  def to_s
    <<~TEXT.truncate(500)
      Title: #{data[:title]}
      Creator: #{data[:creator]}
      Repository: #{data[:repo_owner]}/#{data[:repo]}
      Created at: #{data[:created_at]}
      Updated at: #{data[:updated_at]}
      URL: #{data[:url]}
      Body: #{data[:body]}

      Commits:
      #{commits.join("\n\n")}

      Comments:
      #{comments.join("\n\n")}
    TEXT
  end

  private

  attr_reader :data

  def commits
    data[:commits].map(&:deep_symbolize_keys).map do |commit|
      "  - #{commit[:sha]}: #{commit[:message]} by #{commit[:author][:name]} <#{commit[:author][:email]}> on #{commit[:date]}\n #{commit[:diff]}"
    end
  end

  def comments
    data[:comments].map(&:deep_symbolize_keys).map do |comment|
      <<~TEXT
        - #{comment[:user]} commented on #{comment[:created_at]}:
          #{comment[:body]}
          #{comment[:diff_hunk]}
      TEXT
    end
  end
end
