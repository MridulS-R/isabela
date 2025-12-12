class ApplicationJob < ActiveJob::Base
  # In production we rely on the default async adapter unless configured otherwise.
  # For durable background processing, switch to a persistent adapter (e.g., GoodJob or Sidekiq).
end

