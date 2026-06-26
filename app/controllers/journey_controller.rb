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

  def narrate
    lat = params.require(:lat).to_f
    lng = params.require(:lng).to_f
    result = NarrativeService.call(lat:, lng:)
    if result
      render json: result
    else
      render json: { error: "unavailable" }, status: :service_unavailable
    end
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  end
end
