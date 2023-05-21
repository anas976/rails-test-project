class TriggerController < ApplicationController
  def perform
    render plain: Time.now
    send_event_to_redis
  end

  private

  def send_event_to_redis
    current_time = Time.now
    last_request_time = TriggerLog.last&.last_requested_at

    TriggerLog.create(last_requested_at: current_time)

    if last_request_time.nil? || current_time - last_request_time > REDIS_EVENT_DELAY
      RedisEventWorker.perform_in(REDIS_EVENT_DELAY)
    else
      RedisEventWorker.set(queue: :high).perform_async
    end
  end
end
