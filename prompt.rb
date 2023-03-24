require 'bundler/setup'
Bundler.require
require 'dotenv/load'
require 'uri'
require 'json'

class OpenAI
  API_ENDPOINT = 'https://api.openai.com/v1/completions'.freeze
  MAX_TOKENS = 2048

  attr_reader :errors

  def initialize
    @token = ENV['OPENAI_API_KEY']
    @model = ENV['OPENAI_MODEL']
    @errors = []
  end

  def generate_text(prompt, verbose: false, spinner: true, color: true)
    response_data = request(prompt, spinner: spinner, color: color)
    return handle_errors if errors.any?

    output = format_output(response_data, verbose: verbose, color: color)
    puts output
  end

  private

  def request(prompt, spinner: true, color: true)
    uri = URI.parse(API_ENDPOINT)
    headers = build_headers
    body = build_body(prompt)

    show_spinner(color) if spinner

    response = perform_request(uri, headers, body)

    if spinner
      print "\r#{' ' * (@green_text.length + 4 + 1 + 3)}\r" # Added to clear previous text
    end

    handle_response(response)
  end

  def build_headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@token}"
    }
  end

  def build_body(prompt)
    {
      'model' => @model,
      'prompt' => prompt,
      'max_tokens' => MAX_TOKENS,
      'temperature' => 0
    }
  end

  def show_spinner(color)
    pastel = Pastel.new if color
    @green_text = pastel.green('Consulting with robots...') if color
    spinner = TTY::Spinner.new("[:spinner] #{@green_text}", format: :dots)
    spinner.auto_spin
  end

  def perform_request(uri, headers, body)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Post.new(uri.request_uri, headers)
      request.body = body.to_json
      http.request(request)
    end
  rescue StandardError => e
    e
  end

  def handle_response(response)
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    elsif response.is_a?(SocketError)
      raise StandardError, response.message
    else
      error = JSON.parse(response.body)['error']
      error_message = "#{error['message']}"
      raise StandardError, error_message
    end
  rescue StandardError => e
    errors << e
    nil
  end

  def handle_errors
    errors.each { |error| puts "Error: #{error.message}" }
  end

  def format_output(response_data, verbose:, color:)
    generated_text = response_data['choices'][0]['text']
    usage_info = build_usage_info(response_data, verbose: verbose) if verbose

    if color
      pastel = Pastel.new
      generated_text = pastel.green(generated_text)
      usage_info = pastel.yellow(usage_info) if usage_info
    end

    output = "Answer:\n#{generated_text}"
    output += "\n\nUsage Information:\n#{usage_info}" if usage_info

    output
  end

  def build_usage_info(response_data, verbose:)
    return unless verbose

    usage = response_data['usage']
    prompt_tokens = usage['prompt_tokens']
    completion_tokens = usage['completion_tokens']
    total_tokens = usage['total_tokens']
    "Prompt Tokens: #{prompt_tokens}, Completion Tokens: #{completion_tokens}, Total Tokens: #{total_tokens}"
  end
end

openai = OpenAI.new
openai.generate_text(ARGV.join(' '), verbose: true, spinner: true, color: true)
