require_relative '../app'

describe 'App' do
  include Rack::Test::Methods

  def app
    App
  end

  it "should work" do
    post '/messages'
    puts last_response.body
    expect(last_response).to be_redirect
  end
end
