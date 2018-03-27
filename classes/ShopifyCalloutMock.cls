public with sharing class ShopifyCalloutMock implements HttpCalloutMock {

	protected Integer code;
	protected String status;
	protected String body;
	protected Map<String, String> responseHeaders;

	private static final Integer DEFAULT_CODE = 200;
	private static final String DEFAULT_STATUS = 'OK';
	private static final String DEFAULT_BODY = '';

	public ShopifyCalloutMock(Integer code, String status, String body) {
		this.code = code;
		this.status = status;
		this.body = body;
	}

	public ShopifyCalloutMock(String body) {
		this(DEFAULT_CODE, DEFAULT_STATUS, body);
	}

	public ShopifyCalloutMock() {
		this(DEFAULT_CODE, DEFAULT_STATUS, DEFAULT_BODY);
	}

	public HTTPResponse respond(HTTPRequest req) {

		HttpResponse res = new HttpResponse();
		res.setBody(this.body);
		res.setStatusCode(this.code);
		res.setStatus(this.status);
		return res;
	}
}