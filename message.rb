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
      redis.get('winner_id').to_i
    end

    def create(message)
      message_id = redis.incr 'messages:id'

      message = Message.new(
        'id' => message_id,
        'address' => Database.remove_address,
        'message' => message,
        'time_remaining' => 60 * 10)

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
    Database.redis.hset redis_key, field, value
    Database.redis.zadd 'queue', bid, id
  end

  def poll_blockchain(http)
    response = http.get "/address/#{address}?format=json"
    if response.code == '200'
      begin
        json = JSON.parse(response.body)
        if json.include?('total_received')
          update('bid', json['total_received'])
          Database.logger.info "Updated bid #{bid} field for address #{address}"
        else
          Database.logger.warning "Missing total_received field for address #{address}"
        end
      rescue JSON::ParserError
        Database.logger.warning "Received malformed JSON for address #{address}"
      end
    else
      Database.logger.warning "Received HTTP #{response.code} for address #{address}"
    end
  end
end