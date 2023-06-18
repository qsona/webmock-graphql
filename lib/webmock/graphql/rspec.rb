require_relative "graphql/stub_graphql_request"

RSpec.configure do |config|
  config.include Webmock::Graphql::StubGraphqlRequest
end
