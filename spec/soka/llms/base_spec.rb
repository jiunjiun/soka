# frozen_string_literal: true

RSpec.describe Soka::LLMs::Base do
  let(:test_llm_class) do
    Class.new(described_class) do
      const_set(:ENV_KEY, 'TEST_API_KEY')

      def default_model
        'test-model-v1'
      end

      def base_url
        'https://api.test.com'
      end

      def chat(messages, **_params)
        Soka::LLMs::Result.new(
          model: model,
          content: "Test response for: #{messages.last[:content]}",
          input_tokens: 10,
          output_tokens: 20
        )
      end
    end
  end

  describe '#initialize' do
    context 'with all parameters' do
      it 'initializes with provided values' do
        llm = test_llm_class.new(model: 'custom-model', api_key: 'test-key')
        expect_initialized_values(llm)
      end

      def expect_initialized_values(llm)
        aggregate_failures do
          expect(llm.model).to eq('custom-model')
          expect(llm.api_key).to eq('test-key')
          expect(llm.options).to eq({})
        end
      end
    end

    context 'with default values' do
      it 'uses default model' do
        llm = test_llm_class.new(api_key: 'test-key')
        expect(llm.model).to eq('test-model-v1')
      end

      it 'loads API key from environment' do
        with_env('TEST_API_KEY' => 'env-key') do
          llm = test_llm_class.new
          expect(llm.api_key).to eq('env-key')
        end
      end

      def with_env(env_vars)
        original_values = env_vars.keys.to_h { |k| [k, ENV.fetch(k, nil)] }
        env_vars.each { |k, v| ENV[k] = v }
        yield
      ensure
        original_values.each { |k, v| ENV[k] = v }
      end
    end

    context 'with options' do
      it 'merges provided options with defaults' do
        llm_class_with_defaults = create_llm_class_with_defaults
        llm = llm_class_with_defaults.new(api_key: 'key', max_retries: 5)

        expect_merged_options(llm)
      end

      def create_llm_class_with_defaults
        Class.new(test_llm_class) do
          def default_options
            { max_retries: 3, custom_option: 'value' }
          end
        end
      end

      def expect_merged_options(llm)
        aggregate_failures do
          expect(llm.options[:max_retries]).to eq(5)
          expect(llm.options[:custom_option]).to eq('value')
        end
      end
    end

    context 'with validation' do
      it 'raises error when API key is missing' do
        expect do
          test_llm_class.new(model: 'test')
        end.to raise_error(Soka::LLMError, 'API key is required')
      end

      it 'raises error when API key is empty' do
        expect do
          test_llm_class.new(api_key: '')
        end.to raise_error(Soka::LLMError, 'API key is required')
      end

      it 'raises error when model is nil' do
        custom_class = create_nil_model_class
        expect { custom_class.new(api_key: 'key') }
          .to raise_error(Soka::LLMError, 'Model is required')
      end

      def create_nil_model_class
        Class.new(test_llm_class) do
          def default_model
            nil
          end
        end
      end
    end
  end

  describe '#chat' do
    it 'must be implemented by subclasses' do
      base_llm = described_class.allocate
      expect do
        base_llm.chat([])
      end.to raise_error(NotImplementedError, /must implement #chat method/)
    end

    it 'works in test implementation' do
      llm = test_llm_class.new(api_key: 'key')
      result = llm.chat([{ role: 'user', content: 'Hello' }])

      expect_valid_chat_result(result)
    end

    def expect_valid_chat_result(result)
      aggregate_failures do
        expect(result).to be_a(Soka::LLMs::Result)
        expect(result.content).to include('Test response for: Hello')
        expect(result.model).to eq('test-model-v1')
      end
    end
  end

  describe '#streaming_chat' do
    it 'raises NotImplementedError by default' do
      llm = test_llm_class.new(api_key: 'key')
      expect do
        llm.streaming_chat([])
      end.to raise_error(NotImplementedError, /does not support streaming/)
    end
  end

  describe '#supports_streaming?' do
    it 'returns false by default' do
      llm = test_llm_class.new(api_key: 'key')
      expect(llm.supports_streaming?).to be false
    end
  end

  describe 'abstract methods' do
    let(:minimal_llm_class) do
      Class.new(described_class) do
        const_set(:ENV_KEY, 'TEST_KEY')
      end
    end

    it 'requires default_model implementation' do
      expect do
        minimal_llm_class.new(api_key: 'key')
      end.to raise_error(NotImplementedError, /must implement #default_model/)
    end

    it 'requires base_url implementation' do
      llm_class = create_class_with_model
      llm = llm_class.new(api_key: 'key')
      expect { llm.send(:base_url) }
        .to raise_error(NotImplementedError, /must implement #base_url/)
    end

    def create_class_with_model
      Class.new(minimal_llm_class) do
        def default_model
          'test'
        end
      end
    end
  end

  describe '#connection' do
    let(:llm) { test_llm_class.new(api_key: 'key') }

    it 'creates Faraday connection' do
      conn = llm.send(:connection)
      expect(conn).to be_a(Faraday::Connection)
    end

    it 'configures connection with base URL' do
      conn = llm.send(:connection)
      expect(conn.url_prefix.to_s).to eq('https://api.test.com/')
    end

    it 'sets timeout options' do
      llm_with_timeout = test_llm_class.new(api_key: 'key', timeout: 45)
      conn = llm_with_timeout.send(:connection)

      expect(conn.options.timeout).to eq(45)
    end

    it 'caches connection instance' do
      conn1 = llm.send(:connection)
      conn2 = llm.send(:connection)

      expect(conn1).to be(conn2)
    end
  end

  describe '#handle_error' do
    let(:llm) { test_llm_class.new(api_key: 'key') }

    it 'handles connection failures' do
      error = Faraday::ConnectionFailed.new('failed')
      expect do
        llm.send(:handle_error, error)
      end.to raise_error(Soka::LLMError, /Connection failed/)
    end

    it 'handles client errors' do
      response = { status: 401, body: {} }
      error = Faraday::ClientError.new('client error', response)

      expect do
        llm.send(:handle_error, error)
      end.to raise_error(Soka::LLMError, 'Unauthorized: Invalid API key')
    end

    it 'handles unexpected errors' do
      error = StandardError.new('unexpected')
      expect do
        llm.send(:handle_error, error)
      end.to raise_error(Soka::LLMError, /Unexpected error/)
    end
  end

  describe '#build_error_message' do
    let(:llm) { test_llm_class.new(api_key: 'key') }

    it 'handles 401 status' do
      message = llm.send(:build_error_message, 401, {})
      expect(message).to eq('Unauthorized: Invalid API key')
    end

    it 'handles 429 status' do
      message = llm.send(:build_error_message, 429, {})
      expect(message).to eq('Rate limit exceeded')
    end

    it 'extracts error message from body' do
      body = { 'error' => { 'message' => 'Custom error' } }
      message = llm.send(:build_error_message, 400, body)
      expect(message).to eq('Custom error')
    end

    it 'handles string body' do
      message = llm.send(:build_error_message, 400, 'Error string')
      expect(message).to eq('Error string')
    end

    it 'handles server errors' do
      message = llm.send(:build_error_message, 500, {})
      expect(message).to eq('Server error: 500')
    end
  end
end
