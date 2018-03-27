public with sharing class OrderDto {

	/* Inner class instances */
	public BillingAddress billing_address { get; set; }
	public CustomerDto customer { get; set; }

	public Datetime created_at { get; set; }
	public Datetime completed_at { get; set; }

	public Decimal cart_tax { get; set; }
	public Decimal shipping_tax { get; set; }
	public Decimal subtotal { get; set; }
	public Decimal total_discount { get; set; }
	public Decimal total_shipping { get; set; }
	public Decimal total_tax { get; set; }
	public Decimal total { get; set; }

	public List<CouponCodes> coupon_codes { get; set; }
	public List<LineItems> line_items { get; set; }
	public List<ShippingLines> shipping_lines { get; set; }

	public ShippingAddress shipping_address { get; set; }

	public String customer_ip { get; set; }
	public String email { get; set; }
	public String financial_status { get; set; }
	public String id { get; set; }
	public String landing_site { get; set; }
	public String order_number { get; set; }
	public String processing_method { get; set; }
	public String currencyType { get; set; }

	public List<String> payment_gateway_names { get; set; }

	/* BillingAddres inner class */
	public with sharing class BillingAddress {
		public String first_name { get; set; }
		public String last_name { get; set; }
		public String address_1 { get; set; }
		public String city { get; set; }
//		public String state { get; set; }
		public String postcode { get; set; }
		public String email { get; set; }
		public String phone { get; set; }

		public String province_code { get; set; }
		public String country_code { get; set; }
	}

	/* ShippingAddres inner class */
	public with sharing class ShippingAddress {
		public String first_name { get; set; }
		public String last_name { get; set; }
		public String address_1 { get; set; }
		public String city { get; set; }
//		public String state { get; set; }
		public String postcode { get; set; }
		public String phone { get; set; }

		public String province_code { get; set; }
		public String country_code { get; set; }
	}

	/* LineItems inner class */
	public with sharing class LineItems {
		public Decimal price { get; set; }
		public Decimal quantity { get; set; }

		public String id { get; set; }
		public String orderId { get; set; }
		public String product_id { get; set; }
		public String sku { get; set; }
		public String title { get; set; }
		public String variant_id { get; set; }
	}
	/* CouponCodes inner class */
	public with sharing class CouponCodes {
		public String id { get; set; }
		public String code { get; set; }
		public Decimal amount { get; set; }
		public String type { get; set; }
	}

	public with sharing class ShippingLines {
		public Decimal price { get; set; }
	}

}