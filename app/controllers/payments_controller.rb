require Rails.root.join("lib/paytm_helper.rb")

class PaymentsController < ApplicationController

  include PaytmHelper::EncryptionNewPG
  protect_from_forgery except: [:order_processed]

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

    @checksum_hash = new_pg_checksum(@param_list, Rails.application.secrets[:paytm_credentials][payment_environment][:merchant_key]).gsub("\n",'')

    puts "param_list: #{@param_list}"
    puts "CHECKSUMHASH: #{@checksum_hash}"

    @payment_url = Rails.application.secrets[:paytm_credentials][payment_environment][:web][:payment_url]
  end

  # post /order-processed
  def order_processed
    puts "#{params.to_s}"
  end

end