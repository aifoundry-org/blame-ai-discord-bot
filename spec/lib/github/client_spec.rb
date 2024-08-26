require 'rails_helper'
require 'rest-client'
require 'github/client'

RSpec.describe Github::Client do
  let(:client) { described_class.new }
  let(:valid_url) { "https://github.com/owner/repo/pull/123" }
  let(:invalid_url) { "https://invalid.com/owner/repo/pull/123" }

  describe "#send_get_request" do
    let(:path) { "/some_endpoint" }
    let(:url) { "https://api.github.com#{path}" }
    let(:response) { double("response") }

    context "when the request is successful" do
      before do
        allow(RestClient).to receive(:get).and_return(response)
      end

      it "sends a GET request to the given URL" do
        expect(RestClient).to receive(:get).with(url, anything)
        client.send_get_request(path)
      end

      it "returns the response" do
        result = client.send_get_request(url)
        expect(result).to eq(response)
      end
    end

    context "when the request fails" do
      let(:error_response) { double("error_response") }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      before do
        allow(RestClient).to receive(:get).and_raise(exception)
      end

      it "rescues the exception and returns the response" do
        result = client.send_get_request(path)
        expect(result).to eq(error_response)
      end
    end
  end
end
