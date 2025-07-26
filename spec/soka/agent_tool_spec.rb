# frozen_string_literal: true

RSpec.describe Soka::AgentTool do
  let(:simple_tool_class) do
    Class.new(described_class) do
      desc 'A simple test tool'

      params do
        requires :message, String, desc: 'The message to process'
      end

      def call(message:)
        "Processed: #{message}"
      end
    end
  end

  let(:complex_tool_class) do
    Class.new(described_class) do
      desc 'A complex test tool with validations'

      params do
        requires :name, String, desc: 'User name'
        requires :age, Integer, desc: 'User age', default: 18
        optional :email, String, desc: 'User email'
        optional :tags, Array, desc: 'Tags', default: []

        validates :name, presence: true, length: { minimum: 3, maximum: 50 }
        validates :age, inclusion: { in: 18..100 }
        validates :email, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }
      end

      def call(**params)
        params
      end
    end
  end

  describe '.desc' do
    it 'sets tool description' do
      expect(simple_tool_class.description).to eq('A simple test tool')
    end

    it 'defaults to nil when not set' do
      tool_class = Class.new(described_class)
      expect(tool_class.description).to be_nil
    end
  end

  describe '.params' do
    it 'defines required parameters' do
      params_def = simple_tool_class.params_definition
      expect_required_param_defined(params_def, :message)
    end

    def expect_required_param_defined(params_def, name)
      param = params_def.required_params[name]
      aggregate_failures do
        expect(param).not_to be_nil
        expect(param[:type]).to eq(String)
        expect(param[:desc]).to eq('The message to process')
      end
    end

    it 'defines optional parameters' do
      params_def = complex_tool_class.params_definition
      expect_optional_param_defined(params_def, :email)
    end

    def expect_optional_param_defined(params_def, name)
      param = params_def.optional_params[name]
      aggregate_failures do
        expect(param).not_to be_nil
        expect(param[:type]).to eq(String)
        expect(param[:desc]).to eq('User email')
      end
    end

    it 'supports default values' do
      params_def = complex_tool_class.params_definition
      expect_default_values(params_def)
    end

    def expect_default_values(params_def)
      aggregate_failures do
        expect(params_def.required_params[:age][:default]).to eq(18)
        expect(params_def.optional_params[:tags][:default]).to eq([])
      end
    end

    it 'defines validations' do
      params_def = complex_tool_class.params_definition
      expect_validations_defined(params_def)
    end

    def expect_validations_defined(params_def)
      validations = params_def.validations
      aggregate_failures do
        expect(validations[:name]).to include(presence: true)
        expect(validations[:age]).to include(inclusion: { in: 18..100 })
        expect(validations[:email]).to have_key(:format)
      end
    end
  end

  describe '.tool_name' do
    it 'derives name from class name' do
      stub_const('WeatherTool', Class.new(described_class))
      expect(WeatherTool.tool_name).to eq('weather')
    end

    it 'handles namespaced classes' do
      stub_const('Tools::SearchTool', Class.new(described_class))
      expect(Tools::SearchTool.tool_name).to eq('search')
    end

    it 'works for anonymous classes' do
      tool_class = Class.new(described_class)
      expect { tool_class.tool_name }.not_to raise_error
    end
  end

  describe '.to_h' do
    it 'returns tool schema' do
      schema = simple_tool_class.to_h
      expect_simple_tool_schema(schema)
    end

    def expect_simple_tool_schema(schema)
      expect(schema).to include(
        name: a_kind_of(String),
        description: 'A simple test tool',
        parameters: a_hash_including(
          type: 'object',
          required: include('message')
        )
      )
    end

    it 'includes all parameter properties' do
      schema = complex_tool_class.to_h
      properties = schema[:parameters][:properties]
      expect_all_properties_included(properties)
    end

    def expect_all_properties_included(properties)
      aggregate_failures do
        expect(properties).to have_key('name')
        expect(properties).to have_key('age')
        expect(properties).to have_key('email')
        expect(properties).to have_key('tags')
      end
    end

    it 'converts Ruby types to JSON schema types' do
      schema = complex_tool_class.to_h
      properties = schema[:parameters][:properties]
      expect_correct_json_types(properties)
    end

    def expect_correct_json_types(properties)
      aggregate_failures do
        expect(properties['name'][:type]).to eq('string')
        expect(properties['age'][:type]).to eq('integer')
        expect(properties['tags'][:type]).to eq('array')
      end
    end
  end

  describe '#execute' do
    let(:tool) { simple_tool_class.new }

    context 'with valid parameters' do
      it 'executes successfully' do
        result = tool.execute(message: 'Hello')
        expect_successful_execution(result)
      end

      def expect_successful_execution(result)
        expect(result).to eq('Processed: Hello')
      end
    end

    context 'with missing required parameters' do
      it 'raises ToolError' do
        expect do
          tool.execute
        end.to raise_error(Soka::ToolError, /Missing required parameter: message/)
      end
    end

    context 'with invalid parameter types' do
      it 'raises ToolError for wrong type' do
        expect do
          tool.execute(message: 123)
        end.to raise_error(Soka::ToolError, /Parameter message must be a String/)
      end
    end

    context 'with default values' do
      let(:tool) { complex_tool_class.new }

      it 'uses default values for missing parameters' do
        result = tool.execute(name: 'John', email: 'john@example.com')
        expect_default_values_used(result)
      end

      def expect_default_values_used(result)
        aggregate_failures do
          expect(result[:age]).to eq(18)
          expect(result[:tags]).to eq([])
        end
      end
    end

    context 'with validation rules' do
      let(:tool) { complex_tool_class.new }

      it 'validates presence' do
        expect do
          tool.execute(name: '', age: 25)
        end.to raise_error(Soka::ToolError, /Parameter name can't be blank/)
      end

      it 'validates length minimum' do
        expect do
          tool.execute(name: 'Jo', age: 25)
        end.to raise_error(Soka::ToolError, /Parameter name is too short/)
      end

      it 'validates length maximum' do
        long_name = 'a' * 51
        expect do
          tool.execute(name: long_name, age: 25)
        end.to raise_error(Soka::ToolError, /Parameter name is too long/)
      end

      it 'validates inclusion' do
        expect do
          tool.execute(name: 'John', age: 17)
        end.to raise_error(Soka::ToolError, /Parameter age must be one of/)
      end

      it 'validates format' do
        expect do
          tool.execute(name: 'John', age: 25, email: 'invalid-email')
        end.to raise_error(Soka::ToolError, /Parameter email has invalid format/)
      end

      it 'passes all validations' do
        result = execute_with_valid_params(tool)
        expect(result).to be_a(Hash)
      end

      def execute_with_valid_params(tool)
        tool.execute(
          name: 'John Doe',
          age: 30,
          email: 'john@example.com',
          tags: %w[developer ruby]
        )
      end
    end

    context 'when tool raises an error' do
      let(:error_tool_class) do
        Class.new(described_class) do
          def call(**_params)
            raise StandardError, 'Something went wrong'
          end
        end
      end

      it 'wraps error in ToolError' do
        tool = error_tool_class.new
        expect do
          tool.execute
        end.to raise_error(Soka::ToolError, /Error executing.*Something went wrong/)
      end
    end
  end

  describe '#call' do
    it 'must be implemented by subclasses' do
      base_tool = described_class.new
      expect do
        base_tool.call
      end.to raise_error(NotImplementedError, /must implement #call method/)
    end
  end

  describe 'parameter validation edge cases' do
    let(:edge_case_tool_class) do
      Class.new(described_class) do
        params do
          optional :nullable, String
          optional :with_nil_check, String
          validates :with_nil_check, presence: true
        end

        def call(**params)
          params
        end
      end
    end

    let(:tool) { edge_case_tool_class.new }

    it 'allows nil for optional parameters without validation' do
      expect { tool.execute(nullable: nil) }.not_to raise_error
    end

    it 'handles presence validation on optional parameters' do
      expect do
        tool.execute(with_nil_check: '')
      end.to raise_error(Soka::ToolError, /Parameter with_nil_check can't be blank/)
    end
  end
end
