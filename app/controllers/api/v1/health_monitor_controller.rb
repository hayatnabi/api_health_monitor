require 'net/http'
require 'uri'

class Api::V1::HealthMonitorController < ApplicationController
  def check
    urls = params[:urls]
    return render json: { error: "No URLs provided" }, status: :bad_request if urls.blank?

    results = urls.map do |url|
      check_url_health(url)
    end

    render json: { results: results }
  end

  private

  def check_url_health(url)
    uri = URI.parse(url)
    start_time = Time.now

    response = nil
    latency = nil
    error = nil

    begin
      response = Net::HTTP.get_response(uri)
      latency = ((Time.now - start_time) * 1000).to_i
    rescue StandardError => e
      error = e.message
    end

    {
      url: url,
      status: response&.code || "error",
      latency_ms: latency,
      headers: response&.to_hash,
      error: error
    }
  end
end
