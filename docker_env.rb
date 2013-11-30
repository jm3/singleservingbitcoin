if ENV['REDIS_PORT']
  ENV['REDIS_URL'] = ENV['REDIS_PORT'].gsub(%r(^tcp://), 'redis://')
end
