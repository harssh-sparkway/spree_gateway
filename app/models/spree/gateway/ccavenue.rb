module Spree
  class Gateway::Ccavenue < Gateway
      preference :account_id,  :string
      preference :url,         :string, :default =>  "https://www.ccavenue.com/shopzone/cc_details.jsp"
      preference :working_key, :string
      preference :mode,        :string
      preference :batch_transaction_should_complete_order, :boolean, :default => true

      def payment_profiles_supported?
        true # we want to show the confirm step.
      end

      def provider_class
         ActiveMerchant::Billing::Ccavenue
      end

      def method_type
        'ccavenue'
      end

      def create_profile(payment)
      creditcard = payment.source
      if creditcard.gateway_customer_profile_id.nil?
        options = options_for_create_customer_profile(creditcard, {})
        verify_creditcard_name!(creditcard)
        result = provider.store(creditcard, options)
        if result.success?
          creditcard.update_attributes(:gateway_customer_profile_id => result.params['customerCode'], :gateway_payment_profile_id => result.params['customer_vault_id'])
        else
          payment.send(:gateway_error, result)
        end
      end
    end
private

    def options_for_create_customer_profile(creditcard, gateway_options)
        order = creditcard.payments.first.order
        address = order.bill_address
        { :email=>order.email,
          :billing_address=>
          { :name=>address.full_name,
            :phone=>address.phone,
            :address1=>address.address1,
            :address2=>address.address2,
            :city=>address.city,
            :state=>address.state_name || address.state.abbr,
            :country=>address.country.iso,
            :zip=>address.zipcode
            }
          }.merge(gateway_options)
    end

    def verify_creditcard_name!(creditcard)
        bill_address = creditcard.payments.first.order.bill_address
        creditcard.first_name = bill_address.firstname unless creditcard.first_name?
        creditcard.last_name = bill_address.lastname   unless creditcard.last_name?
    end

  end
end      