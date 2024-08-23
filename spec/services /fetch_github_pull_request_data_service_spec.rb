require 'rails_helper'
require 'json'

RSpec.describe FetchGithubPullRequestDataService do
  let(:pull_request_url) { "https://github.com/owner/repo/pull/123" }
  let(:pull_request_api_url) { "https://api.github.com/repos/owner/repo/pulls/123" }
  let(:service) { described_class.new(pull_request_url) }
  let(:client) { instance_double(Github::Client) }

  let(:pr_data) do
    {
      html_url: pull_request_url,
      title: "Example Pull Request",
      body: "This is a test PR",
      head: {
        repo: {
          owner: { login: "owner" },
          name: "repo"
        }
      },
      user: { login: "creator" },
      created_at: "2023-01-01T00:00:00Z",
      updated_at: "2023-01-02T00:00:00Z",
      diff_url: "https://github.com/owner/repo/pull/123.diff",
      commits_url: "https://api.github.com/repos/owner/repo/pulls/123/commits",
      review_comments_url: "https://api.github.com/repos/owner/repo/pulls/123/comments"
    }
  end

  let(:diff_data) { "diff --git a/file.txt b/file.txt\nindex 83db48f..a8d38ed 100644\n--- a/file.txt\n+++ b/file.txt\n" }

  let(:commits_data) do
    [
      {
        "sha" => "abc123",
        "commit" => {
          "author" => {
            "name" => "John Doe",
            "email" => "john.doe@example.com",
            "date" => "2023-01-01T12:00:00Z"
          }
        }
      }
    ]
  end

  let(:comments_data) do
    [
      {
        "body" => "This is a comment",
        "id" => 1,
        "diff_hunk" => "@@ -0,0 +1,2 @@",
        "path" => "file.txt",
        "user" => { "login" => "commenter" },
        "created_at" => "2023-01-01T12:30:00Z",
        "updated_at" => "2023-01-01T12:45:00Z",
        "reactions" => { "+1" => 1, "-1" => 0 }
      }
    ]
  end

  before do
    allow(Github::Client).to receive(:new).and_return(client)
  end

  describe "#call" do
    context "when all data is successfully fetched" do
      before do
        allow(client).to receive(:send_get_request)
          .with(pull_request_api_url)
          .and_return(instance_double(RestClient::Response, code: 200, body: pr_data.to_json))

        allow(client).to receive(:send_get_request)
          .with(pr_data[:diff_url])
          .and_return(instance_double(RestClient::Response, code: 200, body: diff_data))

        allow(client).to receive(:send_get_request)
          .with(pr_data[:commits_url])
          .and_return(instance_double(RestClient::Response, code: 200, body: commits_data.to_json))

        allow(client).to receive(:send_get_request)
          .with(pr_data[:review_comments_url])
          .and_return(instance_double(RestClient::Response, code: 200, body: comments_data.to_json))
      end

      it "creates a PullRequest with the correct data" do
        expected_data = {
          url: pr_data[:html_url],
          title: pr_data[:title],
          body: pr_data[:body],
          repo_owner: pr_data[:head][:repo][:owner][:login],
          repo: pr_data[:head][:repo][:name],
          creator: pr_data[:user][:login],
          comments: comments_data.map do |comment|
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
          end,
          commits: commits_data.map do |commit|
            {
              sha: commit["sha"],
              author: {
                'name' => commit["commit"]["author"]["name"],
                'email' => commit["commit"]["author"]["email"]
              },
              message: commit["commit"]["message"],
              date: commit["commit"]["author"]["date"]
            }
          end,
          diff: diff_data,
          pr_created_at: pr_data[:created_at],
          pr_updated_at: pr_data[:updated_at]
        }

        expect(PullRequest).to receive(:create).with(expected_data)
        expect(service.call[:status]).to eq(:ok)
      end
    end

    context "when pull request data cannot be fetched" do
      before do
        allow(client).to receive(:send_get_request)
          .with(pull_request_api_url)
          .and_return(instance_double(RestClient::Response, code: 404, body: { message: "Not found" }.to_json))
      end

      it "does not create a PullRequest" do
        expect(PullRequest).not_to receive(:create)
        expect(service.call).to eq({ status: :failed, message: "Not found" })
      end
    end
  end
end
