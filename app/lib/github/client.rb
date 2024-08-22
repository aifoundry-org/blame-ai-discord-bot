class Github::Client
  BASE_URL = 'https://api.github.com'

  def send_get_request(url)
    RestClient.get(url, headers)
  rescue RestClient::ExceptionWithResponse => e
    e.response
  end

  private

  def parse_pull_request_url(url)
    pattern = %r{\Ahttps://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/pull/(?<pr_number>\d+)\z}

    if match_data = url.match(pattern)
      owner = match_data[:owner]
      repo_name = match_data[:repo]
      pull_request_number = match_data[:pr_number]

      { owner: owner, repo_name: repo_name, pull_request_number: pull_request_number }
    else
      raise ArgumentError, "Invalid GitHub pull request URL"
    end
  end

  def headers
    @_headers ||= {
      'X-GitHub-Api-Version' => '2022-11-28',
      'Authorization' => "Bearer #{Rails.application.credentials.github.api_token}",
      'Accept' => 'application/vnd.github+json'
    }
  end
end