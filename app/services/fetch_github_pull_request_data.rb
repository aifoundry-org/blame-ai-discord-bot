class FetchGithubPullRequestData
  attr_reader :pull_request_url, :client

  def initialize(pull_request_url, github_client: Github::Client.new)
    @pull_request_url = pull_request_url
    @client = github_client
  end

  def call
    data = parse_pull_request_url
    pr_data = fetch_pull_request_data(data)

    diff_data = fetch_diff_data(pr_data[:diff_url])
    commits_data = fetch_commits_data(pr_data[:commits_url])
    comments_data = fetch_comments_data(pr_data[:review_comments_url])

    { status: :ok, pull_request: PullRequest.create(assemble_pull_request_data(pr_data, diff_data, commits_data, comments_data)) }
  rescue StandardError => e
    { status: :failed, message: e.message }
  end

  private

  def parse_pull_request_url
    pattern = %r{\Ahttps://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/pull/(?<pr_number>\d+)\z}

    match_data = pull_request_url.match(pattern)

    raise ArgumentError, "Invalid GitHub pull request URL" unless match_data

    {
      owner: match_data[:owner],
      repo_name: match_data[:repo],
      pull_request_number: match_data[:pr_number]
    }
  end

  def fetch_pull_request_data(data)
    response = client.send_get_request("/repos/#{data[:owner]}/#{data[:repo_name]}/pulls/#{data[:pull_request_number]}")

    raise StandardError, JSON.parse(response.body)["message"] unless response.code == 200

    JSON.parse(response.body).deep_symbolize_keys
  end

  def fetch_diff_data(diff_url)
    response = client.send_get_request(URI(diff_url).path)
    response.code == 200 ? response.body : ""
  end

  def fetch_commits_data(commits_url)
    response = client.send_get_request(URI(commits_url).path)

    raise StandardError, JSON.parse(response.body)["message"] unless response.code == 200

    JSON.parse(response.body).map do |commit|
      {
        sha: commit["sha"],
        author: commit["commit"]["author"].slice("name", "email"),
        message: commit["commit"]["message"],
        date: commit["commit"]["author"]["date"]
      }
    end
  end

  def fetch_comments_data(comments_url)
    response = client.send_get_request(URI(comments_url).path)

    raise StandardError, JSON.parse(response.body)["message"] unless response.code == 200

    JSON.parse(response.body).map do |comment|
      {
        body: comment["body"],
        id: comment["id"],
        diff_hunk: comment["diff_hunk"],
        path: comment["path"],
        user: comment["user"]["login"],
        created_at: comment["created_at"],
        updated_at: comment["updated_at"],
        reactions: comment["reactions"].except("url")
      }
    end
  end

  def assemble_pull_request_data(pr_data, diff_data, commits_data, comments_data)
    {
      url: pr_data[:html_url],
      title: pr_data[:title],
      body: pr_data[:body],
      repo_owner: pr_data[:head][:repo][:owner][:login],
      repo: pr_data[:head][:repo][:name],
      creator: pr_data[:user][:login],
      comments: comments_data,
      commits: commits_data,
      diff: diff_data,
      pr_created_at: pr_data[:created_at],
      pr_updated_at: pr_data[:updated_at]
    }
  end
end
