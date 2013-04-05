require 'sinatra'
require 'sinatra/base'
require 'barby/outputter/png_outputter'
require 'barby/barcode/qr_code'

require_relative './database'
require_relative './message'

class App < Sinatra::Base
  configure do
    Compass.add_project_configuration(
        File.join(Sinatra::Application.root, 'compass.rb'))
  end

  helpers do
    def btc_format(number)
      "#{number / 100000000.0} BTC"
    end
  end

  get '/' do
    @winner = Message.find_winner
    render_template :index
  end

  get '/queue' do
    @winner = Message.find_winner
    @queue = Message.eligible
    render_template :queue
  end

  get '/qrcode/:address.png' do
    qr_code = Barby::QrCode.new('bitcoin:' + params[:address])
    outputter = Barby::PngOutputter.new(qr_code)
    outputter.xdim = 5

    content_type 'image/png'

    # Cache for 1 hour
    cache_control :public, :max_age => 3600

    body outputter.to_png
  end

  get '/messages/:id' do
    @message = Message.find(params[:id]) || halt(404)
    render_template :message
  end

  post '/messages' do
    message = Message.create(params[:message])
    redirect "/messages/#{message.id}"
  end

private

  def render_template(template)
    haml template, :locals => {:body_id => "#{template}-body"}
  end

end