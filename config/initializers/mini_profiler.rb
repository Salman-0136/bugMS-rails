if Rails.env.development?
  require "rack-mini-profiler"

  # Prevent double initialization
  Rack::MiniProfilerRails.initialize!(Rails.application) unless defined?(Rack::MiniProfilerRails)

  # Panel options
  Rack::MiniProfiler.config.position = "bottom-right"
  Rack::MiniProfiler.config.start_hidden = false
  Rack::MiniProfiler.config.authorization_mode = :allow_all
end
