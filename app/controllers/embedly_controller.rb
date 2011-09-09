class EmbedlyController < ApplicationController

  def show

    response = {}
    url = params[:url]

    embedly_api = Embedly::API.new :key => '307c64dcab4311e0b1524040d3dc5c07'
    obj = embedly_api.objectify :url => url
    response[:embedly] = obj[0].marshal_dump

    render json: response

  end

end
