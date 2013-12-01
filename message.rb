require 'net/http'

require_relative './database'

class Message < OpenStruct
  class << self
    def redis
      Database.redis
    end

    def find_winner
      id = find_winner_id
      if id
        find(id)
      else
        nil
      end
    end

    def find_winner_id
      winner_id = redis.get('winner_id')
      winner_id ? winner_id.to_i : nil
    end

    def winner_age
      assigned_at = redis.get('winner_assigned_at')
      if assigned_at
         Time.now.to_i - assigned_at.to_i
      else
        nil
      end
    end

    def all
      message_ids = redis.zrevrange('queue', 0, -1).map(&:to_i)
      message_ids.map{ |id| Message.find(id) }
    end

    def eligible
      winner_id = find_winner_id

      all.map{ |message|
        if message.id == winner_id
          message.time_remaining -= winner_age
        end
        message
      }.select{ |message| message.time_remaining > 0 }
    end

    def eligible_with_bids
      eligible.select{ |message| message.bid > 0 }
    end

    def create(message)
      message_id = redis.incr 'messages:id'

      message = Message.new(
        'created_at' => Time.now.to_i,
        'id' => message_id,
        'address' => Database.remove_address,
        'message' => message,
        'time_remaining' => 60 * 60)

      message.save
      message.update_bid(0)
      message
    end

    def find(message_id)
      result = redis.hgetall("messages:#{message_id}")
      if result.empty?
        nil
      else
        result['id'] = message_id.to_i
        result['bid'] = result['bid'].to_i
        result['time_remaining'] = result['time_remaining'].to_i

        Message.new(result)
      end
    end

    def open_blockchain(&proc)
      Net::HTTP.start('blockchain.info', 80, &proc)
    end
  end

  def save
    Database.redis.hmset(redis_key, *@table.to_a.flatten)
  end

  def redis_key
    "messages:#{id}"
  end

  def update_bid(value)
    self.bid = value
    Database.redis.hset redis_key, 'bid', value
    Database.redis.zadd 'queue', bid, id
  end

  def poll_blockchain(http)
    return unless address and address != ''

    response = http.get "/address/#{address}?format=json"
    if response.code == '200'
      begin
        json = JSON.parse(response.body)
        if json.include?('total_received')
          update_bid(json['total_received'])
          Database.logger.info "Updated bid #{bid} field for message #{id} / #{address}"
        else
          Database.logger.warn "Missing total_received field for address #{address}"
        end
      rescue JSON::ParserError
        Database.logger.warn "Received malformed JSON for address #{address}"
      end
    else
      Database.logger.warn "Received HTTP #{response.code} for address #{address}"
    end
  end
end