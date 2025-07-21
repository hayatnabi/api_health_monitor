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

  def history
    url = params[:url]
    return render json: { error: "url is required" }, status: :bad_request if url.blank?
  
    logs = ApiHealthLog.where(url:).order(checked_at: :desc).limit(100)
  
    render json: logs.map { |log|
      {
        status: log.status,
        latency_ms: log.latency_ms,
        headers: JSON.parse(log.headers || '{}'),
        error: log.error,
        checked_at: log.checked_at
      }
    }
  end

  def uptime_summary
    url = params[:url]
    return render json: { error: "url is required" }, status: :bad_request if url.blank?
  
    now = Time.current
    timeframes = {
      "last_24h" => 24.hours.ago..now,
      "last_7d" => 7.days.ago..now
    }
  
    summary = timeframes.transform_values do |range|
      # logs = ApiHealthLog.where(url:, checked_at: range)
      logs = ApiHealthLog.where("url LIKE ?", "%#{url}%")
      total = logs.count
      up = logs.where(status: 200..399).count # status codes 2xx or 3xx considered up
      # up = logs.where(status: /^2|3\d\d/).count # status codes 2xx or 3xx considered up
  
      uptime = total.zero? ? 0.0 : ((up.to_f / total) * 100).round(2)
  
      {
        total_checks: total,
        successful: up,
        failed: total - up,
        uptime_percentage: uptime
      }
    end
  
    # render json: { url:, logs: logs.as_json(only: [:status, :created_at]) }
    render json: { url:, summary: }
  end
  
  def dashboard
    recent = ApiHealthLog
      .select("url, MAX(checked_at) AS last_check, MAX(status) AS last_status")
      .group(:url)
      .limit(50)
  
    dashboard_data = recent.map do |log|
      {
        url: log.url,
        last_status: log.last_status,
        last_checked_at: log.last_check,
        is_up: log.last_status&.start_with?("2", "3")
      }
    end
  
    render json: dashboard_data
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

     # Save log
    ApiHealthLog.create!(
      url: url,
      status: response&.code || "error",
      latency_ms: latency,
      headers: response&.to_hash&.to_json,
      error: error,
      checked_at: Time.now
    )

    {
      url: url,
      status: response&.code || "error",
      latency_ms: latency,
      headers: response&.to_hash,
      error: error
    }
  end
end
