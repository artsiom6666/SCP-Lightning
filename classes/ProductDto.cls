public with sharing class ProductDto {

	/* inner Classes' Instances */
	public List<Image> images {get;set;}
	public List<Variations> variations {get;set;}
	public String description { get; set; }
	public String id { get; set; }
	public String sku { get; set; }
	public String status { get; set; }
	public String title { get; set; }

	/* Image inner class */
	public with sharing class Image {
		public Integer position {get;set;}
		public List<String> variant_ids {get;set;}
		public String alt {get;set;}
		public String id {get;set;}
		public String product_id {get;set;}
		public String src {get;set;}
		public String title {get;set;}
	}

	/* Image inner class */
	public with sharing class Variations {
		public Boolean taxable { get; set; }
		public Decimal price { get; set; }
		public Integer position { get; set; }
		public String id { get; set; }
		public String image_id { get; set; }
		public String product_id { get; set; }
		public String sku { get; set; }
		public String title { get; set; }
	}
}