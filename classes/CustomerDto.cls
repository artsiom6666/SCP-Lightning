public with sharing class CustomerDto {

	/* inner Classes' Instances */
	public BillingAddress billing_address {get;set;}
	public ShippingAddress shipping_address {get;set;}
	
	public String avatar_url {get;set;}
	public String created_at {get;set;}
	public String email {get;set;}
	public String first_name {get;set;}
	public String id {get;set;}
	public String last_name {get;set;}
	public String last_order_date {get;set;}
	public String last_order_id {get;set;}
	public String orders_count {get;set;}
	public String role {get;set;}
	public String total_spent {get;set;}
	public String updated_at {get;set;}
	public String username {get;set;}

	/* inner class */
	public with sharing class BillingAddress {
		public String address_1 {get;set;}
		public String address_2 {get;set;}
		public String city {get;set;}
		public String company {get;set;}
		public String country {get;set;}
		public String email {get;set;}
		public String first_name {get;set;}
		public String last_name {get;set;}
		public String phone {get;set;}
		public String postcode {get;set;}
		public String state {get;set;}
	}

	/* inner Class */
	public with sharing class ShippingAddress {
		public String address_1 {get;set;}
		public String address_2 {get;set;}
		public String city {get;set;}
		public String company {get;set;}
		public String country {get;set;}
		public String first_name {get;set;}
		public String last_name {get;set;}
		public String postcode {get;set;}
		public String state {get;set;}
	}
}