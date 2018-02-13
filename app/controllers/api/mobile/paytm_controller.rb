require Rails.root.join("lib/paytm_helper.rb")

class Api::Mobile::PaytmController < ActionController::Base

  before_action :load_paytm_credentials
  include PaytmHelper::EncryptionNewPG

  # MOBILE
  # post generate-checksum
  def generate_checksum
    payment_environment = :production #(params[:payment_environment] == "production" ? :production : :staging)

    params_keys_to_accept = ["MID", "ORDER_ID", "CUST_ID", "INDUSTRY_TYPE_ID", "CHANNEL_ID", "TXN_AMOUNT",
      "WEBSITE", "CALLBACK_URL", "MOBILE_NO", "EMAIL", "THEME"]
    params_keys_to_ignore = ["USER_ID", "controller", "action", "format"]

    paytmHASH = Hash.new

    paytmHASH["MID"] = @paytm_credentials[:mid]
    paytmHASH["ORDER_ID"] = params["ORDER_ID"]
    paytmHASH["CUST_ID"] = params["CUST_ID"]
    paytmHASH["INDUSTRY_TYPE_ID"] = @paytm_credentials[:industry_type_id]
    paytmHASH["CHANNEL_ID"] = @paytm_credentials[:web][:channel_id]
    paytmHASH["TXN_AMOUNT"] = params["TXN_AMOUNT"]
    paytmHASH["WEBSITE"] = @paytm_credentials[:web][:website]

    keys = params.keys
    keys.each do |key|
      if ! params[key].blank?
        puts "params[#{key}] : #{params[key]}"
        if !(params_keys_to_accept.include? key)
            next
        end
        paytmHASH[key] = params[key]
      end
    end

    mid = paytmHASH["MID"]
    order_id = paytmHASH["ORDER_ID"]

    Rails.logger.debug "paytmHASH: #{paytmHASH}"

    checksum_hash = PaytmHelper::ChecksumTool.new.get_checksum_hash(paytmHASH, @paytm_credentials[:merchant_key]).gsub("\n",'')

    # Prepare the return json.
    returnJson = Hash.new
    returnJson["CHECKSUMHASH"] =  checksum_hash
    returnJson["ORDER_ID"]     =  order_id
    returnJson["payt_STATUS"]  =  1

    Rails.logger.debug "returnJson: #{returnJson}"

    render json: returnJson
  end

  # post verify-checksum
  def verify_checksum
    payment_environment = :production #(params[:payment_environment] == "production" ? :production : :staging)
    params_keys_to_ignore = ["USER_ID", "controller", "action", "format"]

    paytmHASH = Hash.new

    keys = params.keys
    keys.each do |key|
      if (params_keys_to_ignore.include? key)
        next
      end

      paytmHASH[key] = params[key]
    end
    paytmHASH = PaytmHelper::ChecksumTool.new.get_checksum_verified_array(paytmHASH, @paytm_credentials[:merchant_key])

    @response_value = paytmHASH.to_json.to_s.html_safe
  end

  private

  def load_paytm_credentials
    payment_environment = :staging
    if params["payment_environment"].present? && (params["payment_environment"] == "production")
      payment_environment = :production
    end

    @paytm_credentials = Rails.application.secrets.paytm_credentials[payment_environment]
  end

end