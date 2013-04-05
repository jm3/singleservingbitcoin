require 'ostruct'
require 'logger'
require_relative './message'
require_relative './jobs'

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
      redis.watch 'winner_id'

      # Pick the top of the eligible list
      new_winner = Message.eligible_with_bids[0]
      new_winner_id = new_winner ? new_winner.id : new_winner_id

      old_winner_id = Message.find_winner_id
      winner_age = Message.winner_age

      if old_winner_id == new_winner_id
        redis.unwatch
      else
        result = redis.multi do
          # Remove time from the old winner
          if old_winner_id
            redis.hincrby "messages:#{old_winner_id}", 'time_remaining', -winner_age
          end

          # Assign the new winner
          if new_winner_id
            redis.set 'winner_id', new_winner_id
            redis.set 'winner_assigned_at', Time.now.to_i

            Resque.enqueue_in(new_winner.time_remaining, Jobs::PickWinner)
          else
            redis.del 'winner_id'
            redis.del 'winner_assigned_at'
          end
        end
        if result
          if new_winner_id
            logger.info "Assigned a new winner #{new_winner_id}"
          else
            logger.info "There is no current winner"
          end
        end
      end

      new_winner
    end
  end
end