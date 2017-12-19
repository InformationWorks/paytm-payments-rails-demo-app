class PaytmHelper::ChecksumTool
  
  include PaytmHelper::EncryptionNewPG

  def self.is_valid_merchant_id?(mid)
    return mid.eql?(MID)
  end

  def get_checksum_hash(paytmparams, merchant_key)
    return new_pg_checksum(paytmparams, merchant_key)
  end

  def get_checksum_verified_array(paytmparams, merchant_key)
    checksum_hash = paytmparams["CHECKSUMHASH"]
		paytmparams.delete("CHECKSUMHASH")
    return_array = paytmparams		
		
    is_valid_checksum = new_pg_verify_checksum(paytmparams, checksum_hash, merchant_key)
    if(is_valid_checksum)
      return_array["IS_CHECKSUM_VALID"] = "Y"
    else
      return_array["IS_CHECKSUM_VALID"] = "N"
    end
    return return_array
  end

end