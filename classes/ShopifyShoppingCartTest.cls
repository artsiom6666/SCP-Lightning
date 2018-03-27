@isTest
private class ShopifyShoppingCartTest {

	@istest public static void getProductsTest() {

		String products7 = '{"products":[{"id":9664375876},{"id":9664371844},{"id":9664360900},{"id":9664383620},{"id":9664365252},{"id":9664368196},{"id":9664393988}]}';
		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(products7));

		Test.startTest();
			List<ProductDto> productsList = new List<ProductDto>(ShopifyShoppingCart.getProducts());
		Test.stopTest();

		System.assertEquals(7, productsList.size());
	}

	@istest public static void getCustomersTest() {

		CustomerDto dto = new CustomerDto();
		dto.avatar_url = 'test';
		dto.created_at = 'test';
		dto.email = 'test';
		dto.first_name = 'test';
		dto.id = 'test';
		dto.last_name = 'test';
		dto.last_order_date = 'test';
		dto.last_order_id = 'test';
		dto.orders_count = 'test';
		dto.role = 'test';
		dto.total_spent = 'test';
		dto.updated_at = 'test';
		dto.username = 'test';

		CustomerDto.BillingAddress bAddr = new CustomerDto.BillingAddress();
		bAddr.address_1 = 'test';
		bAddr.address_2 = 'test';
		bAddr.city = 'test';
		bAddr.company = 'test';
		bAddr.country = 'test';
		bAddr.email = 'test';
		bAddr.first_name = 'test';
		bAddr.last_name = 'test';
		bAddr.phone = 'test';
		bAddr.postcode = 'test';
		bAddr.state = 'test';
		dto.billing_address = bAddr;

		CustomerDto.ShippingAddress sAddr = new CustomerDto.ShippingAddress();
		sAddr.first_name = 'test';
		sAddr.last_name = 'test';
		sAddr.company = 'test';
		sAddr.address_1 = 'test';
		sAddr.address_2 = 'test';
		sAddr.city = 'test';
		sAddr.state = 'test';
		sAddr.postcode = 'test';
		sAddr.country = 'test';
		dto.shipping_address = sAddr;

		System.assertNotEquals(null, dto);

		String customers36 = '{"customers":[{"id":5294891204,"email":"mhbugg@embarqmail.com"},{"id":5294616900,"email":"drewbova83@gmail.com"},{"id":5294568900,"email":"drewbdrew@test.com"},{"id":5293535364,"email":"rodojo@embarqmail.com"},{"id":5292138180,"email":"smehta@mcnabbus.com"},{"id":5291268164,"email":"a.ibanezburgos@gmail.com"},{"id":5290122884,"email":"rbthai3@yahoo.com"},{"id":5288363204,"email":"mnpicard888@hotmail.com"},{"id":5287154180,"email":"scromey123@hotmail.com"},{"id":5278441476,"email":"vickis@skilonline.com"},{"id":5274909700,"email":"judith.badeau@aon.com"},{"id":5274054276,"email":"aaosga@sina.com"},{"id":5272893380,"email":"joeavg46@gmail.com"},{"id":5256299972,"email":"mashadeca@windstream.net"},{"id":5248162052,"email":"sunderwood33@yahoo.com"},{"id":5248085508,"email":"rwjman01@yahoo.com"},{"id":5246723588,"email":"ramirezmaria.mr@gmail.com"},{"id":5243521412,"email":"caitlindoermer@gmail.com"},{"id":5235943812,"email":"klegart@comcast.net"},{"id":5232086404,"email":"tmorabito@mcnabbus.com"},{"id":5231995972,"email":"savannahdeskins54@gmail.com"},{"id":5231923332,"email":"lorenaramirez0944@hotmail.com"},{"id":5231802436,"email":"lisa.reynolds0913@gmail.com"},{"id":5231798596,"email":"cateteam@catemcnabbcosmetics.com"},{"id":5230056004,"email":"jacques.heyer@gmail.com"},{"id":5227171588,"email":"jkozak86@gmail.com"},{"id":5226123716,"email":"katehenson@drhenson.org"},{"id":5223595076,"email":"heatheronealmakeup@gmail.com"},{"id":5220307780,"email":"andrahenriques@hotmail.com"},{"id":5218271172,"email":"lreynolds@mcnabbus.com"},{"id":5218271108,"email":"aherzberg@mcnabbus.com"},{"id":5218263108,"email":"john.doe@shopify.com"},{"id":5217719300,"email":"aherzberg@touchcr.com"},{"id":5217675844,"email":"test@mcnabbus.com"},{"id":5214704452,"email":"pa.cucchiara@att.net"},{"id":5175582724,"email":"abova@mcnabbus.com"}]}';

		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(customers36));

		Test.startTest();
			List<CustomerDto> customersList = new List<CustomerDto>(ShopifyShoppingCart.getCustomers());
		Test.stopTest();

		System.assertEquals(36, customersList.size());
	}

	@istest public static void getOrdersTest() {

		String orders27 = '{"orders":[{"id":4817121668,"total_price":"30.95"},{"id":4815560836,"total_price":"29.98"},{"id":4814146436,"total_price":"9.35"},{"id":4814144772,"total_price":"21.48"},{"id":4814141380,"total_price":"21.48"},{"id":4814138372,"total_price":"21.48"},{"id":4813268932,"total_price":"29.98"},{"id":4812089732,"total_price":"59.98"},{"id":4810032260,"total_price":"29.99"},{"id":4804780804,"total_price":"29.98"},{"id":4800649796,"total_price":"29.99"},{"id":4783244036,"total_price":"33.98"},{"id":4726131524,"total_price":"37.96"},{"id":4724816836,"total_price":"21.48"},{"id":4724813764,"total_price":"9.35"},{"id":4724661124,"total_price":"33.04"},{"id":4724624452,"total_price":"9.35"},{"id":4723714308,"total_price":"17.70"},{"id":4722061124,"total_price":"29.98"},{"id":4721266052,"total_price":"25.50"},{"id":4717867652,"total_price":"101.95"},{"id":4715968388,"total_price":"33.04"},{"id":4715826500,"total_price":"9.35"},{"id":4715802628,"total_price":"21.48"},{"id":4715777092,"total_price":"49.58"},{"id":4714415940,"total_price":"18.18"},{"id":4712583108,"total_price":"21.48"}]}';

		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(orders27));

		Test.startTest();
			List<OrderDto> ordersList = new List<OrderDto>(ShopifyShoppingCart.getOrders());
		Test.stopTest();

		System.assertEquals(27, ordersList.size());
	}
}