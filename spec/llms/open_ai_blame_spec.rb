# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OpenAI Pull Request Blame' do
  subject(:assertion_result) { assertion.call(runner_result) }

  let(:pull_request) { FetchGithubPullRequestData.new(ENV['PULL_REQUEST_URL']).call[:pull_request] }

  let(:maximum_response_lenth) { 2000 }
  let(:prompt) { build_model_prompt("You are a helpful model summarizing GitHub pull request.
                                     Try to response in a manner that would get a developer up to speed.
                                     Return PR info including creator username, title and etc.
                                     Omit unnecessary information, note any decisions made in discussions. Don't use more than #{maximum_response_lenth} characters.
                                     Strip all html tags unless they are relevant to discussion. This is PR data: #{pull_request.to_json}") }

  let(:assertion) { build_model_assertion(:include_all, pull_request.title, pull_request.creator) }
  let(:runner_result) { model_runner.call(model_configuration, prompt) }
  let(:model_runner) { build_model_runner(:openai, access_token: ENV['OPENAI_ACCESS_TOKEN']) }
  let(:model_configuration) { build_model_configuration(:openai, model:, temperature:) }
  let(:temperature) { 0.5 }

  context 'with gpt-4o-mini model' do
    let(:model) { 'gpt-4o-mini' }

    it "returns PR title and creator name" do
      is_expected.to be_passed
    end

    it "less or equal maximum response length" do
      expect(runner_result.to_s.length).to be <= maximum_response_lenth
    end
  end

  context 'with gpt-4o model' do
    let(:model) { 'gpt-4o' }

    it 'returns PR title and creator name' do
      is_expected.to be_passed
    end

    it "less or equal maximum response length" do
      expect(runner_result.to_s.length).to be <= maximum_response_lenth
    end
  end

  context 'with gpt-4-turbo model' do
    let(:model) { 'gpt-4-turbo' }

    it 'returns PR title and creator name' do
      is_expected.to be_passed
    end

    it "less or equal maximum response length" do
      expect(runner_result.to_s.length).to be <= maximum_response_lenth
    end
  end
end
