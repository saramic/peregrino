# frozen_string_literal: true

class JourneyController < ApplicationController
  def start
  end

  def locate
    location = IpGeolocationService.call
    if location
      render json: location
    else
      render json: { error: "unavailable" }, status: :service_unavailable
    end
  end
end
