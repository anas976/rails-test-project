# lib/rate_limiter.rb
require 'redis'

module RateLimiter
  REDIS_KEY = 'request_queue'.freeze

  def self.process_request
    redis = Redis.new

    if redis.zcard(REDIS_KEY) == 0
      enqueue_request(redis)
      request_id = redis.zrange(REDIS_KEY, 0, 0)[0]
      RequestProcessorWorker.perform_async(request_id)
      puts "Enqueued request #{request_id}"
    else
      request_time = redis.zrange(REDIS_KEY, 0, 0, withscores: true)[0][1]
      if request_time + 60 <= Time.now.to_i
        request_id = redis.zrange(REDIS_KEY, 0, 0)[0]
        redis.zremrangebyrank(REDIS_KEY, 0, 0)
        enqueue_request(redis)
        RequestProcessorWorker.perform_async(request_id)
        puts "Replaced and enqueued request #{request_id}"
      end
    end

    puts "Total Requests: #{redis.zcard(REDIS_KEY)}"
    puts "Remaining Requests: #{redis.zcard(REDIS_KEY)}"
    puts "Processing Requests: #{Sidekiq::Queue.new.size}"
  end

  private_class_method

  def self.enqueue_request(redis)
    request_id = SecureRandom.uuid
    redis.zadd(REDIS_KEY, Time.now.to_i, request_id)
    request_id
  end
end
