# frozen_string_literal: true

require_relative "graphql/version"

module Webmock
  module Graphql
    # Example:
    #
    # Webmock::Graphql.register(:hoge, "query($foo: Int!) { bar baz }") do
    #   params do
    #     foo
    #     bar { 1 } # default value
    #   end
    #   variables do
    #     { foo: foo }
    #   end
    #   data do
    #     { bar: bar, baz: 2 }
    #   end
    # end
    class BuilderContextClassFactory
      def self.new(query)
        Class.new do
          @query = query

          def initialize(**args)
            args.each do |name, value|
              instance_variable_set("@#{name}", value)
            end
          end

          def variables
            pr = self.class.variables_proc
            pr && instance_exec(&pr)
          end

          def data
            pr = self.class.data_proc
            pr && instance_exec(&pr)
          end

          def errors
            pr = self.class.errors_proc
            pr && instance_exec(&pr)
          end

          class << self
            attr_reader :query
            attr_accessor :variables_proc, :data_proc, :errors_proc
          end

          def query
            self.class.query
          end
        end
      end
    end

    class ParamsContext
      def initialize(builder_context_class)
        @builder_context_class = builder_context_class
      end
      attr_reader :builder_context_class

      def method_missing(name, &block)
        builder_context_class.define_method(name) do
          # self == builder_context instance
          vname = "@#{name}"
          if instance_variable_defined?(vname)
            instance_variable_get(vname)
          elsif block
            instance_exec(&block)
          else
            raise "#{name} is not passed"
          end
        end
      end

      def respond_to_missing?(sym, include_private)
        true
      end
    end

    class RegisterContext
      # attr_reader :variables_proc, :data_proc, :errors_proc
      attr_reader :builder_context_class
      def initialize(query)
        @builder_context_class = BuilderContextClassFactory.new(query)
      end

      def params(&block)
        params_context = ParamsContext.new(@builder_context_class)
        params_context.instance_exec(&block)
      end

      def variables(&block)
        builder_context_class.variables_proc = block
      end

      def data(&block)
        builder_context_class.data_proc = block
      end

      def errors(&block)
        builder_context_class.errors_proc = block
      end
    end

    @stub_hash = {}
    class << self
      attr_accessor :default_url
      attr_reader :stub_hash

      def register(name, query, &block)
        raise "stub #{name} is already registered" if stub_hash[name]

        register_context = RegisterContext.new(query)
        register_context.instance_exec(&block)

        stub_hash[name] = register_context.builder_context_class
      end

      def reset!
        self.default_url = nil
        @stub_hash = {}
      end
    end

    module StubGraphqlRequest
      # stub_graphql_request(:hoge, a: 1, b: 2)
      def stub_graphql_request(name, url = nil, **args)
        builder_context_class = Webmock::Graphql.stub_hash[name]
        raise "stub #{name} is not registered" unless builder_context_class

        stub_graphql_context = builder_context_class.new(**args)

        url ||= Webmock::Graphql.default_url
        raise "url is not set" if url.nil?

        WebMock.stub_request(:post, url).with(
          body: {
            query: stub_graphql_context.query,
            variables: stub_graphql_context.variables
          }
        ).to_return(
          body: {
            data: stub_graphql_context.data,
            errors: stub_graphql_context.errors
          }.to_json,
          headers: {"Content-Type" => "application/json"}
        )
      end
    end

    # enable `Webmock::Graphql.stub_graphql_request`
    extend StubGraphqlRequest
  end
end
