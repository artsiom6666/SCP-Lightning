public with sharing class ShopifyShoppingCart {
	/* Parse Object */
	private static JSONParser parser{ get;set; }

	/**
	* Get all customers
	* @return JSON string
	*/
	public Static List<CustomerDto> getCustomers(){
		List<CustomerDto> customerList;
		try {
			String customers =  ShopifyShoppingAPIClient.get_customers();
			customers = customers.substring(1, customers.length()-1);
			customers = customers.replace('address1','address_1').replace('address2','address_2').replace('zip','postcode').replace('\\','');
			parser = JSON.createParser(customers);
			customerList = new List<CustomerDto>();
			while (parser.nextToken() != null) {
				if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
					while(parser.nextToken() != null)  {
						if(parser.getCurrentToken() == JSONToken.START_OBJECT) {
							CustomerDto customer = (CustomerDto)parser.readValueAs(CustomerDto.class);
							customerList.add(customer);
						}
					}
				}
			}
		}
		catch(Exception e) {}

		return customerList;
	}

	/**
	* Get all products
	* @return JSON string
	*/
	public Static List<ProductDto> getProducts(){
		List<ProductDto> productList;
		try {
			String result =  ShopifyShoppingAPIClient.get_products();
			String products = result.substring(1, result.length()-1);
			products = products.replace('product_type','type').replace('variants','variations')
				.replace('requires_shipping','shipping_required').replace('inventory_quantity','stock_quantity').replace('\\\\"','');
			products = products.replace('\\','').replace('\'','');
			parser = JSON.createParser(products);
			productList = new List<ProductDto>();
			while (parser.nextToken() != null) {
				if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
					while(parser.nextToken() != null)  {
						if(parser.getCurrentToken() == JSONToken.START_OBJECT) {
							ProductDto product = (ProductDto)parser.readValueAs(ProductDto.class);
							productList.add(product);
						}
					}
				}
			}
		}
		catch(Exception e) {}

		return productList;
	}

	/**
	* Get all orders
	* @return JSON string
	*/
	public Static List<OrderDto> getOrders(){
		List<OrderDto> ordersList;
		try {
			String orders =  ShopifyShoppingAPIClient.get_orders();
			orders = orders.substring(1, orders.length()-1);
			orders = orders.replace('total_price', 'total') .replace('currency', 'currencyType').replace('address1','address_1')
				.replace('address2','address_2').replace('zip','postcode').replace('order_status_url','status')
				.replace('processed_at','completed_at').replace('browser_ip','customer_ip').replace('browser_ip','customer_ip')
				.replace('subtotal_price','subtotal').replace('total_discounts','total_discount').replace('discount_codes','coupon_codes')
				.replace('\\','');
			parser = JSON.createParser(orders);
			ordersList = new List<OrderDto>();
			while (parser.nextToken() != null) {
				if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
					while(parser.nextToken() != null)  {
						if(parser.getCurrentToken() == JSONToken.START_OBJECT) {
							OrderDto order = (OrderDto)parser.readValueAs(OrderDto.class);
							ordersList.add(order);
						}
					}
				}
			}

		}
		catch(Exception e) {}

		return ordersList;
	}

}