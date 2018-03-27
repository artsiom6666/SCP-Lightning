@isTest
global class AmazonSyncAPIMock implements HttpCalloutMock {
	global HTTPResponse respond(HttpRequest req) {

		String incomingEndpoint = req.getEndpoint();

		System.assertEquals(false, String.isBlank(req.getEndpoint()));

		String countryCode = TouchCRHelper.isSCPEnabled() == TRUE ? '<CountryCode>US</CountryCode>\n' : '';

		HttpResponse res = new HttpResponse();
		if (incomingEndpoint.contains('Action=RequestReport')) {
			res.setStatusCode(200);
			String body = '<?xml version="1.0"?>\n' +
							'<RequestReportResponse xmlns="http://mws.amazonaws.com/doc/2009-01-01/">\n' +
							  '<RequestReportResult>\n' +
							    '<ReportRequestInfo>\n' +
							      '<ReportType>_GET_MERCHANT_LISTINGS_DATA_</ReportType>\n' +
							      '<ReportProcessingStatus>_SUBMITTED_</ReportProcessingStatus>\n' +
							      '<EndDate>2016-09-21T00:00:00+00:00</EndDate>\n' +
							      '<Scheduled>false</Scheduled>\n' +
							      '<ReportRequestId>54959017065</ReportRequestId>\n' + 
							      '<SubmittedDate>2016-09-21T11:16:26+00:00</SubmittedDate>\n' +
							      '<StartDate>2016-08-19T00:00:00+00:00</StartDate>\n' +
							    '</ReportRequestInfo>\n' +
							  '</RequestReportResult>\n' +
							  '<ResponseMetadata>\n' +
							    '<RequestId>97d33e38-bbd3-4ac4-be4c-4fbe491238d3</RequestId>\n' +
							  '</ResponseMetadata>\n' +
							'</RequestReportResponse>\n';
			res.setBody(body);
		}
		if (incomingEndpoint.contains('Action=GetReportRequestList')) {
			res.setStatusCode(200);
			res.setBody('<?xml version="1.0"?><GetReportRequestListResponse xmlns="http://mws.amazonservices.com/doc/2009-01-01/"><GetReportRequestListResult><NextToken>2YgYW55IPQhcm5hbCBwbGVhc3VyZS4=</NextToken><HasNext>true</HasNext><ReportRequestInfo><ReportRequestId>2291326454</ReportRequestId><ReportType>_GET_MERCHANT_LISTINGS_DATA_</ReportType><StartDate>2011-01-21T02:10:39+00:00</StartDate><EndDate>2011-02-13T02:10:39+00:00</EndDate><Scheduled>false</Scheduled><SubmittedDate>2011-02-17T23:44:09+00:00</SubmittedDate><ReportProcessingStatus>_DONE_</ReportProcessingStatus><GeneratedReportId>3538561173</GeneratedReportId><StartedProcessingDate>2011-02-17T23:44:43+00:00</StartedProcessingDate><CompletedDate>2011-02-17T23:44:48+00:00</CompletedDate></ReportRequestInfo></GetReportRequestListResult><ResponseMetadata><RequestId>732480cb-84a8-4c15-9084-a46bd9a0889b</RequestId></ResponseMetadata></GetReportRequestListResponse>');
		}

		if (incomingEndpoint.contains('Action=GetReport')) {
			res.setStatusCode(200);
			String body = 'item-name	item-description	listing-id	seller-sku	price	quantity	open-date	image-url	item-is-marketplace	product-id-type	zshop-shipping-fee	item-note	item-condition	zshop-category1	zshop-browse-path	zshop-storefront-feature	asin1	asin2	asin3	will-ship-internationally	expedited-shipping	zshop-boldface	product-id	bid-for-featured-placement	add-delete	pending-quantity	fulfillment-channel\n' + 
			'Cate McNabb Cosmetics Natural Auburn Eyebrow Pencil	Cate McNabb mineral-based brow pencils are long-wearing and smudge-resistant. The pencils, crafted with a trio of waxes, make for convenient application with a natural, full-brow result. When filling in the brow, softer shorter strokes work best for a natural look.	1006PAFY84Q	#1522	14	69	2015-10-06 12:26:10 PDT		y	5			11				B00K1IX6SO			1			5406BA6EF2C25447			0	DEFAULT\n' + 
			'Cate McNabb Cosmetics Makeup Primer	The perfect prep to your beauty routine. Don\'t let your makeup smudge off halfway through the party; primer helps it last all night long.	1006PAFYC2E	#1584	8	56	2015-10-06 12:26:19 PDT		y	5			11				B00K1IXEY0			1			5406BA78D7A22D70			0	DEFAULT\n' + 
			'Cate McNabb Cosmetics Makeup Remover	Our makeup remover is like nothing else! Saturate a cotton pad and use it to remove your day\'s makeup. Works on everything from foundation to our no-budging gel eyeliner! Make sure to shake before use.	1006PAFYD28	#1607	18	74	2015-10-06 12:26:21 PDT		y	5			11				B00K1IXDYG			1			5406BA7A87E7D8ED			0	DEFAULT\n' + 
			'Cate McNabb Cosmetics Foundation Brush	The Cate McNabb soft-bristled, flat foundation brush allows for a flawless, streak-free foundation application. Perfect for applying Cate McNabb cream foundation.	1006PAFYDSW	#1645	28	75	2015-10-06 12:26:23 PDT		y	5			11				B00K1IXKIK			1			5406BA7C53588A87			0	DEFAULT\n' + 
			'Cate McNabb Cosmetics Eyeshadow Brush	For all of your eyeshadow needs. A staple item for the makeup bag, this brush works with pressed and loose eyeshadows.	1006PAFYENQ	#1652	24	74	2015-10-06 12:26:25 PDT		y	5			11				B00K1IXOCC			1			5406BA7E14F31DA6			0	DEFAULT\n' +
			'Cate McNabb Cosmetics Eyeshadow Brush	For all of your eyeshadow needs. A staple item for the makeup bag, this brush works with pressed and loose eyeshadows.	1006PAFYENQ	#1652	24	74	2015-10-06 12:26:25 PDT		y	5			11				B00K1IXOCC			1			5406BA7E14F31DA6			0	DEFAULT\n' +
			'Cate McNabb Cosmetics Crease/Blending Brush	Great for achieving smoked out drama with precise crease-color application or for defined contour creation, the Cate McNabb blending crease brush is a perfect accessory brush for a bolder look.	1006PAFYFB2	#1669	22	75	2015-10-06 12:26:27 PDT		y	5			11				B00K1IXPQ2			1			5406BA7FCA8CA642			0	DEFAULT\n';
			res.setBody(body);
		}

		if (incomingEndpoint.contains('Action=GetProductCategoriesForASIN')) {
			res.setStatusCode(200);
			String body = '<?xml version="1.0"?>\n' + 
							'<GetProductCategoriesForASINResponse xmlns="http://mws.amazonservices.com/schema/Products/2011-10-01">\n' +
							'<GetProductCategoriesForASINResult>\n' +
							  '<Self>\n' +
							    '<ProductCategoryId>2420095011</ProductCategoryId>\n' +
							    '<ProductCategoryName>Compression Shorts</ProductCategoryName>\n' +
							    '<Parent>\n' +
							      '<ProductCategoryId>2419332011</ProductCategoryId>\n' +
							      '<ProductCategoryName>Men</ProductCategoryName>\n' +
							      '<Parent>\n' +
							        '<ProductCategoryId>2371051011</ProductCategoryId>\n' +
							        '<ProductCategoryName>Clothing</ProductCategoryName>\n' +
							        '<Parent>\n' +
							          '<ProductCategoryId>3403201</ProductCategoryId>\n' +
							            '<ProductCategoryName>Bikes &#x26; Accessories</ProductCategoryName>\n' +
							          '<Parent>\n' +
							            '<ProductCategoryId>2232464011</ProductCategoryId>\n' +
							              '<ProductCategoryName>Bikes &#x26; Scooters</ProductCategoryName>\n' +
							            '<Parent>\n' +
							              '<ProductCategoryId>3375301</ProductCategoryId>\n' +
							              '<ProductCategoryName>Categories</ProductCategoryName>\n' +
							              '<Parent>\n' +
							                '<ProductCategoryId>3375251</ProductCategoryId>\n' +
							                '<ProductCategoryName>Categories</ProductCategoryName>\n' +
							              '</Parent>\n' +
							            '</Parent>\n' +
							          '</Parent>\n' +
							        '</Parent>\n' +
							      '</Parent>\n' +
							    '</Parent>\n' +
							  '</Self>\n' +
							'</GetProductCategoriesForASINResult>\n' +
							'<ResponseMetadata>\n' +
							  '<RequestId>fbce5b62-67cc-4ab8-86f3-EXAMPLE22e4e</RequestId>\n' +
							'</ResponseMetadata>\n' +
							'</GetProductCategoriesForASINResponse>\n';
			res.setBody(body);
		}

		if (incomingEndpoint.contains('Action=ListOrders')) {
			res.setStatusCode(200);
			String body = '<?xml version="1.0"?>\n' + 
							'<ListOrdersResponse xmlns="https://mws.amazonservices.com/Orders/2013-09-01">' + 
							  '<ListOrdersResult>' + 
							    '<Orders>' + 
							      '<Order>' + 
							        '<LatestShipDate>2016-08-19T14:49:12Z</LatestShipDate>\n' + 
							        '<OrderType>StandardOrder</OrderType>\n' + 
							        '<PurchaseDate>2016-08-19T00:52:51Z</PurchaseDate>\n' + 
							        '<BuyerEmail>m98by0kytny4zn3@marketplace.amazon.com</BuyerEmail>\n' + 
							        '<AmazonOrderId>102-0234210-7177800</AmazonOrderId>\n' + 
							        '<LastUpdateDate>2016-08-19T14:51:15Z</LastUpdateDate>\n' + 
							        '<NumberOfItemsShipped>1</NumberOfItemsShipped>\n' + 
							        '<ShipServiceLevel>SecondDay</ShipServiceLevel>\n' + 
							        '<OrderStatus>Shipped</OrderStatus>\n' + 
							        '<SalesChannel>Amazon.com</SalesChannel>\n' + 
							        '<IsBusinessOrder>false</IsBusinessOrder>\n' + 
							        '<NumberOfItemsUnshipped>0</NumberOfItemsUnshipped>\n' + 
							        '<BuyerName>Jana Gutchess</BuyerName>\n' + 
							        '<OrderTotal>' + 
							          '<CurrencyCode>USD</CurrencyCode>\n' + 
							          '<Amount>18.00</Amount>\n' + 
							        '</OrderTotal>\n' + 
							        '<IsPremiumOrder>false</IsPremiumOrder>\n' + 
							        '<EarliestShipDate>2016-08-19T14:49:12Z</EarliestShipDate>\n' + 
							        '<MarketplaceId>ATVPDKIKX0DER</MarketplaceId>\n' + 
							        '<FulfillmentChannel>AFN</FulfillmentChannel>\n' + 
							        '<PaymentMethod>Other</PaymentMethod>\n' + 
							        '<ShippingAddress>' + 
							          '<StateOrRegion>NY</StateOrRegion>\n' + 
							          '<City>CORTLAND</City>\n' + 
							          countryCode + 
							          '<PostalCode>13045-9123</PostalCode>\n' + 
							          '<Name>Jana Gutchess</Name>\n' + 
							          '<AddressLine1>4071 QUAIL RDG</AddressLine1>\n' + 
							        '</ShippingAddress>\n' + 
							        '<IsPrime>false</IsPrime>\n' + 
							        '<ShipmentServiceLevelCategory>SecondDay</ShipmentServiceLevelCategory>\n' + 
							        '<SellerOrderId>102-0234210-7177800</SellerOrderId>\n' + 
							      '</Order>\n' + 
							    '</Orders>\n' + 
							    '<LastUpdatedBefore>2016-09-21T14:47:13Z</LastUpdatedBefore>\n' + 
							    '<NextToken>DpYxHTJsuDN/YYuZQbKv1QafEPREmauvizt1MIhPYZZruKc26+xAiJcPl3yIn2jA49aumpSurCzNeGyEmOrLe7q8xqAchQNKtU38YwqRuVIwqcbUqh/LhCJ0wMvlylZkE3RvwDUQBA2RfspgeNygJZlWME1t9fKZYxOzqAAIIwtCSnzBCNDFTx35jNz11rwF42UBJZmIuaKELwRPgB5hiP0IfGeAvb95J/gMIjfO756fpVJGS+vu5pFHMXy6XL5lF+yuWwoHlreBwslpY7RkzmylJ2RZvGh5sJdJobvDtjbZkLh8ZQWZdmTZrNwXH6VTRw/CY97ddEkBiLzBxHwEA3nDfFR3PPcGA9rNUA+mtRW7As8guvF8R2b7MtFtmIzieTReIqZ9kqt2W1XjrucVXrMHptWT4qyy0JAwySPky/arFgkhTxL4mtIAtOtO5wMIrIo9RYzq+pnGGVwO4u32HQ9FdiqGNuiO0Snj6iLUysdAmTynrNRZYA==</NextToken>\n' + 
							  '</ListOrdersResult>\n' + 
							  '<ResponseMetadata>' + 
							    '<RequestId>cde630d1-9390-435e-95f7-f319c213647c</RequestId>\n' + 
							  '</ResponseMetadata>\n' + 
							'</ListOrdersResponse>\n';
			res.setBody(body);
		}

		if (incomingEndpoint.contains('Action=ListOrdersByNextToken')) {
			res.setStatusCode(200);
			String body = '<?xml version="1.0"?>\n' + 
							'<ListOrdersResponse xmlns="https://mws.amazonservices.com/Orders/2013-09-01">' + 
							  '<ListOrdersResult>' + 
							    '<Orders>' + 
							      '<Order>' + 
							        '<LatestShipDate>2016-08-19T14:49:12Z</LatestShipDate>\n' + 
							        '<OrderType>StandardOrder</OrderType>\n' + 
							        '<PurchaseDate>2016-08-19T00:52:51Z</PurchaseDate>\n' + 
							        '<BuyerEmail>m98by0kytny4zn3@marketplace.amazon.com</BuyerEmail>\n' + 
							        '<AmazonOrderId>102-0234210-7177800</AmazonOrderId>\n' + 
							        '<LastUpdateDate>2016-08-19T14:51:15Z</LastUpdateDate>\n' + 
							        '<NumberOfItemsShipped>1</NumberOfItemsShipped>\n' + 
							        '<ShipServiceLevel>SecondDay</ShipServiceLevel>\n' + 
							        '<OrderStatus>Shipped</OrderStatus>\n' + 
							        '<SalesChannel>Amazon.com</SalesChannel>\n' + 
							        '<IsBusinessOrder>false</IsBusinessOrder>\n' + 
							        '<NumberOfItemsUnshipped>0</NumberOfItemsUnshipped>\n' + 
							        '<BuyerName>Jana Gutchess</BuyerName>\n' + 
							        '<OrderTotal>' + 
							          '<CurrencyCode>USD</CurrencyCode>\n' + 
							          '<Amount>18.00</Amount>\n' + 
							        '</OrderTotal>\n' + 
							        '<IsPremiumOrder>false</IsPremiumOrder>\n' + 
							        '<EarliestShipDate>2016-08-19T14:49:12Z</EarliestShipDate>\n' + 
							        '<MarketplaceId>ATVPDKIKX0DER</MarketplaceId>\n' + 
							        '<FulfillmentChannel>AFN</FulfillmentChannel>\n' + 
							        '<PaymentMethod>Other</PaymentMethod>\n' + 
							        '<ShippingAddress>' + 
							          '<StateOrRegion>NY</StateOrRegion>\n' + 
							          '<City>CORTLAND</City>\n' + 
							          countryCode + 
							          '<PostalCode>13045-9123</PostalCode>\n' + 
							          '<Name>Jana Gutchess</Name>\n' + 
							          '<AddressLine1>4071 QUAIL RDG</AddressLine1>\n' + 
							        '</ShippingAddress>\n' + 
							        '<IsPrime>false</IsPrime>\n' + 
							        '<ShipmentServiceLevelCategory>SecondDay</ShipmentServiceLevelCategory>\n' + 
							        '<SellerOrderId>102-0234210-7177800</SellerOrderId>\n' + 
							      '</Order>\n' + 
							    '</Orders>\n' + 
							    '<LastUpdatedBefore>2016-09-21T14:47:13Z</LastUpdatedBefore>\n' + 							    
							  '</ListOrdersResult>\n' + 
							  '<ResponseMetadata>' + 
							    '<RequestId>cde630d1-9390-435e-95f7-f319c213647c</RequestId>\n' + 
							  '</ResponseMetadata>\n' + 
							'</ListOrdersResponse>\n';
			res.setBody(body);
		}

		if (incomingEndpoint.contains('Action=ListOrderItems')) {
			res.setStatusCode(200);
			String body = '<?xml version="1.0"?>\n' + 
							'<ListOrderItemsResponse xmlns="https://mws.amazonservices.com/Orders/2013-09-01">\n' + 
							  '<ListOrderItemsResult>\n' + 
							    '<OrderItems>\n' + 
							      '<OrderItem>\n' + 
							        '<QuantityOrdered>1</QuantityOrdered>\n' + 
							        '<Title>Cate McNabb Cosmetics Natural Sheer Eyeshadow Primer, Extend Eyeshadow Wear on Any Skin Tone, 0.18 Ounce</Title>\n' + 
							        '<PromotionDiscount>\n' + 
							          '<CurrencyCode>USD</CurrencyCode>\n' + 
							          '<Amount>0.00</Amount>\n' + 
							        '</PromotionDiscount>\n' + 
							        '<ASIN>B00K1IXFU8</ASIN>\n' + 
							        '<SellerSKU>#2512</SellerSKU>\n' + 
							        '<OrderItemId>11720205748578</OrderItemId>\n' + 
							        '<QuantityShipped>1</QuantityShipped>\n' + 
							        '<ItemPrice>\n' + 
							          '<CurrencyCode>USD</CurrencyCode>\n' + 
							          '<Amount>18.00</Amount>\n' + 
							        '</ItemPrice>\n' + 
							        '<ItemTax>\n' + 
							          '<CurrencyCode>USD</CurrencyCode>\n' + 
							          '<Amount>0.00</Amount>\n' + 
							        '</ItemTax>\n' + 
							      '</OrderItem>\n' + 
							    '</OrderItems>\n' + 
							    '<AmazonOrderId>102-0234210-7177800</AmazonOrderId>\n' + 
							  '</ListOrderItemsResult>\n' + 
							  '<ResponseMetadata>\n' + 
							    '<RequestId>70ad0539-5965-44e4-a096-f8e8fb841322</RequestId>\n' + 
							  '</ResponseMetadata>\n' + 
							'</ListOrderItemsResponse>\n';
			res.setBody(body);
		}

		return res;
	}
}