require 'bundler'
require 'resque/tasks'
require 'resque_scheduler/tasks'
require 'rspec/core/rake_task'

Bundler.require

require_relative './database'
require_relative './docker_env'

task :pick_winner do
  message = Database.pick_winner
  if message
    puts "The current winner is [#{message.id}] #{message.message}"
  else
    puts "There is no current winner"
  end
end

desc 'Polls blockchain.info to update all the bid values'
task :poll_blockchain do
  Jobs::PollBlockchain.perform
end

desc 'Reads the `addressess` file and adds it to redis'
task :import_addresses do
  count = 0
  File.open('addresses', 'r') do |file|
    until file.eof?
      address = file.readline.chomp

      if Bitcoin::valid_address?(address)
        result = Database.add_address(address)
        count += 1 if result
      else
        puts "Skipping invalid address: #{address}"
      end
    end
  end
  puts "Imported #{count} addresses"
end

desc 'Generate keys.json and addresses files'
task :generate_keypairs do
  keys = 1000.times.collect do
    private_key, public_key = Bitcoin::generate_key
    address = Bitcoin::pubkey_to_address(public_key)
    {
      'private_key' => private_key,
      'public_key' => public_key,
      'address' => address
    }
  end

  %w(keys.json addresses).each do |filename|
    raise "File already exists: #{filename}" if File.exists?(filename)
  end

  puts "Writing file keys.json"
  File.open('keys.json', 'w') do |file|
    file.puts keys.to_json
  end

  puts "Writing file addresses"
  File.open('addresses', 'w') do |file|
    keys.each do |item|
      file.puts item['address']
    end
  end
end

namespace :resque do
  task :setup do
    require_relative './jobs'

    Resque.schedule = {
      'poll_blockchain' => {
        'every' => '1m',
        'class' => Jobs::PollBlockchain
      }
    }
  end
end

RSpec::Core::RakeTask.new do |task|
  task.rspec_opts = ["-r ./spec/spec_helper.rb"]
  task.pattern    = 'spec/*_spec.rb'
end
