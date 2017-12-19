class PaytmHelper::Utility
  
  include PaytmHelper::EncryptionNewPG

  # Check if the checksum is valid for the parameters received from
  # PayTm. This is requrired to make sure that the request is received from PayTm.
  def is_checksum_valid?(received_params)
    paytmparams = Hash.new

    keys = received_params.keys
    keys.each do |k|
      paytmparams[k] = received_params[k]
    end

    checksum_hash = paytmparams["CHECKSUMHASH"]
    paytmparams.delete("CHECKSUMHASH")

    Rails.logger.debug "HERE"
    Rails.logger.debug "paytmparams #{paytmparams}"
    Rails.logger.debug "checksum_hash #{checksum_hash}"
    Rails.logger.debug "PAYTM_MERCHANT_KEY #{ENV["PAYTM_MERCHANT_KEY"]}" 
        
    return new_pg_verify_checksum(paytmparams, checksum_hash, ENV["PAYTM_MERCHANT_KEY"])
  end

  def self.status_check_api_response(order_code, txn_status_url, mid)
    
    url_string = "#{txn_status_url}?JsonData={\"MID\":\"#{mid}\",\"ORDERID\":\"#{order_code}\"}"
    # url_string = "#{"https://secure.paytm.in/oltp/HANDLER_INTERNAL/TXNSTATUS"}?JsonData={\"MID\":\"#{"EDUCAT63222514557661"}\",\"ORDERID\":\"#{order_code}\"}"
    puts "url_string: #{url_string}"

    begin
      response = HTTParty.get(url_string)
      json_response = JSON.parse(response)
      return json_response
    rescue Exception => e
      puts "status_check_api_response Exception: #{e.message}"
      return JSON.parse({ STATUS: "TXN_FAILURE" })
    end
    
  end

end