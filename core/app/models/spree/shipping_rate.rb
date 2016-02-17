module Spree
  # Records the costs of different shipping methods for a shipment and which
  # method has been selected to deliver the shipment.
  #
  class ShippingRate < Spree::Base
    belongs_to :shipment, class_name: 'Spree::Shipment'
    belongs_to :shipping_method, -> { with_deleted }, class_name: 'Spree::ShippingMethod', inverse_of: :shipping_rates

    has_many :taxes,
             class_name: "Spree::ShippingRateTax",
             foreign_key: "shipping_rate_id",
             dependent: :destroy

    delegate :order, :currency, to: :shipment
    delegate :name, :tax_category, :tax_category_id, to: :shipping_method
    delegate :code, to: :shipping_method, prefix: true
    alias_attribute :amount, :cost

    alias_method :discounted_amount, :amount

    extend DisplayMoney
    money_methods :amount

    def display_price
      price = display_base_price.to_s
      if tax_rate && tax_rate.show_rate_in_label?
        tax_amount = calculate_tax_amount
        if tax_amount != 0
          if tax_rate.included_in_price?
            if tax_amount > 0
              amount = "#{display_tax_amount(tax_amount)} #{tax_rate.name}"
              price += " (#{Spree.t(:incl)} #{amount})"
            else
              amount = "#{display_tax_amount(tax_amount*-1)} #{tax_rate.name}"
              price += " (#{Spree.t(:excl)} #{amount})"
            end
          else
            amount = "#{display_tax_amount(tax_amount)} #{tax_rate.name}"
            price += " (+ #{amount})"
          end
        end
      end
      price
    end
    alias_method :display_cost, :display_price

    private

    def tax_label_separator
      Spree.t :tax_label_separator, scope: 'shipping_rate.display_price'
    end
  end
end
