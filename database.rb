require 'ostruct'
require 'logger'
require_relative './message'

class Database
  class << self
    def redis
      @@redis ||= Redis.new
    end

    def add_address(address)
      redis.sadd('bitcoin_addresses', address)
    end

    def remove_address
      redis.spop('bitcoin_addresses')
    end

    def logger
      @@logger ||= Logger.new(STDOUT)
    end

    def pick_winner
      new_winner_id = redis.zrevrange('queue', 0, 0)[0]

      if new_winner_id
        redis.watch 'winner_id'

        if Message.find_winner_id == new_winner_id
          redis.unwatch
        else
          result = redis.multi do
            redis.set 'winner_id', new_winner_id
            redis.set 'winner_assigned_at', Time.now.to_i
          end
          if result
            logger.info "Assigned a new winner #{new_winner_id}"
          end
        end
      else
        redis.del 'winner_id'
        redis.del 'winner_assigned_at'
      end
    end

    def winner_age
      assigned_at = redis.get('winner_assigned_at')
      if assigned_at
         Time.now.to_i - assigned_at.to_i
      else
        nil
      end
    end

    def queue
      message_ids = redis.zrevrange('queue', 0, -1).map(&:to_i)

      winner_id = Message.find_winner_id

      message_ids.map do |id|
        Message.find(id).tap do |message|
          if message.id == winner_id
            message.time_remaining -= winner_age
          end
        end
      end
    end
  end
end