module Jobs
  class PollBlockchain
    @queue = :poll_blockchain

    def self.perform
      Message.open_blockchain do |http|
        Message.all.each do |message|
          message.poll_blockchain(http)
        end
      end

      Database.pick_winner
    end
  end

  class PickWinner
    @queue = :pick_winner

    def self.perform
      Database.pick_winner
    end
  end
end