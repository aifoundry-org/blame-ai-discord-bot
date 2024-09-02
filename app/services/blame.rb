class Blame
  def initialize(pull_request_url)
    @pull_request_url = pull_request_url
  end

  def call
    result = FetchGithubPullRequestData.new(pull_request_url).call
    Rails.logger.info("Pull request data: #{result}")
    pull_request_data = PullRequestData.new(result)

    assistant.add_message content: pull_request_data.to_s
    assistant.run
    assistant.messages.last.content
  end

  private

  attr_reader :pull_request_url

  def llm
    @llm ||= Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
  end

  def assistant
    @assistant ||= Langchain::Assistant.new(
      llm: llm,
      instructions: "
        You are a helpful discord bot summarizing GitHub pull request.
        Each user message will have embedded Pull Request details. Try to response in a manner that would get a developer up to speed.
        Use discord message formatting. Omit unnecessary information, note any decisions made in discussions. Don't use more than 2000 characters.
        Strip all html tags unless they are relevant to discussion.",
    )
  end
end
