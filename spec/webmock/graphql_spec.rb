# frozen_string_literal: true

require "net/http"

RSpec.describe Webmock::Graphql do
  before(:each) do
    WebMock.enable!
  end

  after(:each) do
    Webmock::Graphql.reset!
    WebMock.reset!
  end

  it "has a version number" do
    expect(Webmock::Graphql::VERSION).not_to be nil
  end

  it "webmock is enabled" do
    http = Net::HTTP.new("www.webmock-graphql-example.com")
    expect { http.post("/index.html", "") }.to raise_error(WebMock::NetConnectNotAllowedError)
  end

  describe "stub_graphql_request" do
    describe "with passing url" do
      subject { Webmock::Graphql.stub_graphql_request(stub_name, url, **args) }

      let(:stub_name) { :test_query }
      let(:url) { "http://www.webmock-graphql-example.com/graphql" }
      let(:args) { {} }

      context "when not registered" do
        it "raises error" do
          expect { subject }.to raise_error(/not registered/)
        end
      end

      context "when registered" do
        let(:query) { "query($id: ID!) { user(id: $id) { name age } }" }
        before do
          Webmock::Graphql.register(stub_name, query) do
            params do
              id
            end
            variables do
              {id: id}
            end
            data do
              {name: "name", age: "age"}
            end
          end
        end

        context "when not passsing params" do
          it "raises error" do
            expect { subject }.to raise_error(/not passed/)
          end
        end

        context "when passing params" do
          let(:args) { {id: "user123"} }
          it do
            expect { subject }.not_to raise_error
            # further assertions are in "send graphql request" section
          end
        end
      end
    end

    describe "without passing url" do
      subject { Webmock::Graphql.stub_graphql_request(stub_name, **args) }

      let(:stub_name) { :test_query }
      let(:query) { "query($id: ID!) { user(id: $id) { name age } }" }
      before do
        Webmock::Graphql.register(stub_name, query) do
          params do
            id
          end
          variables do
            {id: id}
          end
          data do
            {name: "name", age: "age"}
          end
        end
      end

      let(:args) { {id: "user123"} }

      context "when default_url is not set" do
        it "raises error" do
          expect { subject }.to raise_error(/not set/)
        end
      end

      context "when default_url is set" do
        before { Webmock::Graphql.default_url = "http://www.webmock-graphql-example.com/graphql" }
        it do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe "send graphql request" do
    subject(:send_graphql_request) { http.post(graphql_path, body, headers) }

    let(:http) { Net::HTTP.new(hostname) }
    let(:hostname) { "www.webmock-graphql-example.com" }
    let(:wrong_hostname) { "www.webmock-graphql-wrong-example.com" }
    let(:graphql_path) { "/graphql" }
    let(:url) { "http://#{hostname}#{graphql_path}" }
    let(:wrong_url) { "http://#{wrong_hostname}#{graphql_path}" }
    let(:query) { "query($id: ID!) { user(id: $id) { name age } }" }
    let(:body) { {query: query, variables: variables}.to_json }
    let(:variables) { {id: id} }
    let(:id) { "user123" }

    let(:headers) { {"Content-Type": "application/json"} }
    let(:stub_name) { :test_query }

    context "when no stubs" do
      it { expect { send_graphql_request }.to raise_error(WebMock::NetConnectNotAllowedError) }
    end

    context "when stub is registered" do
      before do
        Webmock::Graphql.register(stub_name, query) do
          params do
            id
          end
          variables do
            {id: id}
          end
          data do
            {user: {name: "name", age: "age"}}
          end
        end
      end

      context "when stubbed" do
        before { Webmock::Graphql.stub_graphql_request(stub_name, url, id: id) }

        it do
          response = send_graphql_request
          body = JSON.parse(response.body)
          expect(body["data"]["user"]).to eq({"name" => "name", "age" => "age"})
          expect(body["errors"]).to eq nil
        end
      end

      context "when stubbed wrongly" do
        before { Webmock::Graphql.stub_graphql_request(stub_name, wrong_url, id: id) }

        it { expect { send_graphql_request }.to raise_error(WebMock::NetConnectNotAllowedError) }
      end
    end

    context "when default_url is set" do
      before do
        Webmock::Graphql.default_url = url

        Webmock::Graphql.register(stub_name, query) do
          params do
            id
          end
          variables do
            {id: id}
          end
          data do
            {user: {name: "name", age: "age"}}
          end
        end
      end

      context "when stubbed" do
        before { Webmock::Graphql.stub_graphql_request(stub_name, id: id) }

        it do
          response = send_graphql_request
          body = JSON.parse(response.body)
          expect(body["data"]["user"]).to eq({"name" => "name", "age" => "age"})
          expect(body["errors"]).to eq nil
        end
      end

      context "when stubbed wrongly" do
        before { Webmock::Graphql.stub_graphql_request(stub_name, wrong_url, id: id) }

        it "overwrites url" do
          expect { send_graphql_request }.to raise_error(WebMock::NetConnectNotAllowedError)
        end
      end
    end
  end
end
