# frozen_string_literal: true

class JourneyController < ApplicationController
  def start
  end

  def locate
    location = IpGeolocationService.call(ip: request.remote_ip)
    if location
      render json: location
    else
      render json: { error: "unavailable" }, status: :service_unavailable
    end
  end

  def locality
    lat = params.require(:lat).to_f
    lng = params.require(:lng).to_f
    result = LocalityService.call(lat:, lng:)
    if result
      render json: { place: result[:place] }
    else
      render json: { error: "unavailable" }, status: :service_unavailable
    end
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  end

  def narrate
    lat = params.require(:lat).to_f
    lng = params.require(:lng).to_f
    place   = params[:place].presence
    result  = NarrativeService.call(lat:, lng:, place:)
    if result
      render json: result
    else
      render json: { error: "unavailable" }, status: :service_unavailable
    end
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  end
end
