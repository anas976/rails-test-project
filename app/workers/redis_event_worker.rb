class RedisEventWorker
  include Sidekiq::Worker

  def perform
    Redis.new.publish('events', Time.now.to_s)
    after_perform
  end

  def after_perform
    queue = Sidekiq::Queue.new(:high)
    return unless queue.size.positive?

    job = queue.first
    Sidekiq::Client.push(
      'queue' => :default,
      'class' => job.klass,
      'args' => job.args,
      'at' => Time.now.to_i + REDIS_EVENT_DELAY
    )
    job.delete
  end
end
