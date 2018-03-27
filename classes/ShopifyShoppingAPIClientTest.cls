@isTest
private class ShopifyShoppingAPIClientTest {

	@istest public static void test_makeapicallbydate() {

		String products7 = '{"products":[{"id":9664375876},{"id":9664371844},{"id":9664360900},{"id":9664383620},{"id":9664365252},{"id":9664368196},{"id":9664393988}]}';

		Test.setMock(HttpCalloutMock.class, new ShopifyCalloutMock(products7));

		Test.startTest();
			String result = ShopifyShoppingAPIClient.make_api_call_by_date('count', 'products', '');
		Test.stopTest();

		Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(result);

		System.assertEquals(1, parsedResponse.size());
	}
}