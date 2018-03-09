require Rails.root.join("lib/paytm_helper.rb")

class PaymentsController < ApplicationController

  include PaytmHelper::EncryptionNewPG
  protect_from_forgery except: [:order_processed]

  #WEB
  # post /proceed-to-pay
  def proceed_to_pay

    # Test by switching between staging and production credentials.
    payment_environment = (params[:payment_environment] == "production" ? :production : :staging)

    @param_list = Hash.new

    order_id = params["ORDER_ID"]
    cust_id = params["CUST_ID"]
    txn_amount = params["TXN_AMOUNT"]
    mobile_no = params["MOBILE_NO"]
    email = params["EMAIL"]

    @param_list["MID"] = Rails.application.secrets[:paytm_credentials][payment_environment][:mid]
    @param_list["ORDER_ID"] = order_id
    @param_list["CUST_ID"] = cust_id
    @param_list["INDUSTRY_TYPE_ID"] = Rails.application.secrets[:paytm_credentials][payment_environment][:industry_type_id]
    @param_list["CHANNEL_ID"] = Rails.application.secrets[:paytm_credentials][payment_environment][:web][:channel_id]
    @param_list["TXN_AMOUNT"] = txn_amount
    @param_list["MOBILE_NO"] = mobile_no
    @param_list["EMAIL"] = email
    @param_list["WEBSITE"] = Rails.application.secrets[:paytm_credentials][payment_environment][:web][:website]
    @param_list["CALLBACK_URL"] = Rails.application.secrets[:paytm_credentials][payment_environment][:web][:callback_url]

    puts "---#{@param_list}---"
    puts "---#{Rails.application.secrets[:paytm_credentials][payment_environment][:merchant_key]}---"
    @checksum_hash = new_pg_checksum(@param_list, Rails.application.secrets[:paytm_credentials][payment_environment][:merchant_key]).gsub("\n",'')

    puts "param_list: #{@param_list}"
    puts "CHECKSUMHASH: #{@checksum_hash}"

    @payment_url = Rails.application.secrets[:paytm_credentials][payment_environment][:web][:payment_url]
  end

  # post /order-processed
  def order_processed
    puts "#{params.to_s}"
  end

  # MOBILE
  # post generate-checksum
  def generate_checksum
    payment_environment = (params[:payment_environment] == "production" ? :production : :staging)

    params_keys_to_accept = ["MID", "ORDER_ID", "CUST_ID", "INDUSTRY_TYPE_ID", "CHANNEL_ID", "TXN_AMOUNT",
      "WEBSITE", "CALLBACK_URL", "MOBILE_NO", "EMAIL", "THEME"]
    params_keys_to_ignore = ["USER_ID", "controller", "action", "format"]

    paytmHASH = Hash.new

    paytmHASH["MID"] = Rails.application.secrets[:paytm_credentials][payment_environment][:mid]
    paytmHASH["ORDER_ID"] = params["ORDER_ID"]
    paytmHASH["CUST_ID"] = params["CUST_ID"]
    paytmHASH["INDUSTRY_TYPE_ID"] = Rails.application.secrets[:paytm_credentials][payment_environment][:industry_type_id]
    paytmHASH["CHANNEL_ID"] = Rails.application.secrets[:paytm_credentials][payment_environment][:web][:channel_id]
    paytmHASH["TXN_AMOUNT"] = params["TXN_AMOUNT"]
    paytmHASH["WEBSITE"] = Rails.application.secrets[:paytm_credentials][payment_environment][:web][:website]

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

    checksum_hash = PaytmHelper::ChecksumTool.new.get_checksum_hash(paytmHASH, Rails.application.secrets[:paytm_credentials][payment_environment][:merchant_key]).gsub("\n",'')

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
    payment_environment = (params[:payment_environment] == "production" ? :production : :staging)
    params_keys_to_ignore = ["USER_ID", "controller", "action", "format"]

    paytmHASH = Hash.new

    keys = params.keys
    keys.each do |key|
      if (params_keys_to_ignore.include? key)
        next
      end

      paytmHASH[key] = params[key]
    end
    paytmHASH = PaytmHelper::ChecksumTool.new.get_checksum_verified_array(paytmHASH, Rails.application.secrets[:paytm_credentials][payment_environment][:merchant_key])

    @response_value = paytmHASH.to_json.to_s.html_safe
  end
end