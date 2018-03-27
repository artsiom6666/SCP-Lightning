public with sharing class AmazonAccountMergeController {

	public String amazonNamespacePrefix {get; set;}

	public Account mergeAcc {get; set;}
	public Account similarAcc {get; set;}

	public String mergeAccId {get; set;}
	public String similarAccId {get; set;}

	public List<Account> highProbability {get; set;}
	public List<Account> mediumProbability {get; set;}

	String highQueryStr;
	String mediumQueryStr;
	String queryFields;
	Set<String> mergeFieldSet;
	Map<String, String>	fieldTypeMap;

	public Map<String, String> mergeAccFieldsMap {get; set;}
	public Map<String, String> similarAccFieldsMap {get; set;}
	public Map<String, String> fieldAPINameFieldLabelMap {get; set;}

	public String JSONDataToMerge {get; set;}

	public Boolean isConflictsToMerge {get; set;}
	public Boolean AccNotSelected {get; set;}
	public Boolean displayPopup {get; set;}

	public String jsonMergedValues {get; set;}

	private Boolean checkCRUD_FLS() {
		Boolean result = Schema.getGlobalDescribe().get('Account').getDescribe().isMergeable() ? true : false;

		Schema.FieldSet fldSet = Schema.getGlobalDescribe().get('Account').getDescribe().fieldSets.getMap().get(amazonNamespacePrefix + 'Merge_Field_Set');

		Map<String, Schema.SObjectField> accountFieldsMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();

		for (String fieldAPI : mergeFieldSet) {
			Schema.SObjectField objField = accountFieldsMap.get(fieldAPI);
			if ( !objField.getDescribe().isUpdateable() || !objField.getDescribe().isAccessible() ) {
				result = false;
			}
		}

		result = Schema.sObjectType.Account.fields.isMergeable__c.isUpdateable() ? result : false;

		return result;
	}

	public AmazonAccountMergeController(ApexPages.StandardController stdController) {

		ApexClass cs = [SELECT NamespacePrefix FROM ApexClass WHERE Name = 'AmazonAccountMergeController'];
		this.amazonNamespacePrefix = cs.NamespacePrefix;
		this.amazonNamespacePrefix = !String.isBlank(this.amazonNamespacePrefix) ? this.amazonNamespacePrefix + '__' : '';

		this.AccNotSelected = true;
		this.displayPopup = false;

		this.mergeAccId = stdController.getId();
		this.mergeAcc = (Account)stdController.getRecord();

		this.mergeFieldSet = getMergeFieldSetValues();
		this.fieldTypeMap = getFieldSetTypes(mergeFieldSet);

		this.queryFields = '';
		for (String fld : this.mergeFieldSet) {
			this.queryFields += fld + ', ';
		}
		this.queryFields = queryFields.removeEnd(', ');
		this.queryFields += ' ';

		String masterAccQuery = 'SELECT Id, ' + queryFields + 'FROM Account WHERE Id = \'' + this.mergeAccId + '\' LIMIT 1' ;

		this.mergeAcc = Database.query(masterAccQuery);

		String scpBilCode = '';
		String scpShipCode = '';
		String helpChar = '';

		if (TouchCRHelper.isSCPEnabled() == TRUE) {
			scpBilCode = '(BillingCountryCode ' + getSOQLvalue(String.valueOf(mergeAcc.get('BillingCountryCode'))) + ' ' +
				'AND BillingStateCode ' + getSOQLvalue(String.valueOf(mergeAcc.get('BillingStateCode'))) + ') ' + 
				'OR (';
			scpShipCode = '(ShippingCountryCode ' + getSOQLvalue(String.valueOf(mergeAcc.get('ShippingCountryCode'))) + ' ' +
				'AND ShippingStateCode ' + getSOQLvalue(String.valueOf(mergeAcc.get('ShippingStateCode'))) + ') ' + 
				'OR (';
				helpChar = ') ';
		}
		

		this.highQueryStr = 'SELECT Id, ' + queryFields + ' FROM Account ' +
			'WHERE ( FirstName ' + getSOQLvalue(mergeAcc.FirstName) + ' ' +
			'OR LastName ' + getSOQLvalue(mergeAcc.LastName) + ') ' +

			'AND (' + 
			scpBilCode +
			'Original_Country__c ' + getSOQLvalue(mergeAcc.Original_Country__c) + ' ' +
			'AND Original_State__c ' + getSOQLvalue(mergeAcc.Original_State__c) + helpChar + 

			') ' + 

			'AND (BillingStreet ' + getSOQLvalue(mergeAcc.BillingStreet) + ' ' +
			'OR BillingCity ' + getSOQLvalue(mergeAcc.BillingCity) + ' ' + 
			'OR BillingPostalCode ' + getSOQLvalue(mergeAcc.BillingPostalCode) + ') ' +
			'AND Id != \'' + mergeAccId + '\' LIMIT 5';

		this.mediumQueryStr = 'SELECT Id, ' + queryFields + ' FROM Account ' +
			'WHERE ( FirstName ' + getSOQLvalue(mergeAcc.FirstName) + ' ' +
			'OR LastName ' + getSOQLvalue(mergeAcc.LastName) + ') ' +

			'AND (' + 
			scpShipCode +
			'Original_Country__c ' + getSOQLvalue(mergeAcc.Original_Country__c) + ' ' +
			'AND Original_State__c ' + getSOQLvalue(mergeAcc.Original_State__c) + helpChar + 

			') ' + 

			'AND (ShippingStreet ' + getSOQLvalue(mergeAcc.ShippingStreet) + ' ' +
			'OR ShippingCity ' + getSOQLvalue(mergeAcc.ShippingCity) + ' ' + 
			'OR ShippingPostalCode ' + getSOQLvalue(mergeAcc.ShippingPostalCode) + ') ' +
			'AND Id != \'' + mergeAccId + '\' LIMIT 5';

		this.highProbability = Database.query(this.highQueryStr);
		this.mediumProbability = Database.query(this.mediumQueryStr);

		if(!checkCRUD_FLS()) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Insufficient priveleges.'));
		}
	}

	public PageReference doMerge() {

		AccNotSelected = false;

		this.mergeAccFieldsMap = new Map<String, String>();
		this.similarAccFieldsMap = new Map<String, String>();

		for (String fldname : this.mergeFieldSet) {
			if (String.isBlank( String.valueOf(this.mergeAcc.get(fldname)) )  ) {
				this.mergeAccFieldsMap.put(fldname, '' );
			}
			else {
				this.mergeAccFieldsMap.put(fldname, String.valueOf(this.mergeAcc.get(fldname)) );
			}
		}

		this.similarAcc = Database.query('SELECT Id, ' + this.queryFields + 'FROM Account WHERE Id = \'' + this.similarAccId + '\' LIMIT 1' );
		for (String fldname : this.mergeFieldSet) {
			if (String.isBlank( String.valueOf(this.similarAcc.get(fldname)) )  ) {
				this.similarAccFieldsMap.put(fldname, '' );
			}
			else {
				this.similarAccFieldsMap.put(fldname, String.valueOf(this.similarAcc.get(fldname)) );
			}
		}

		this.JSONDataToMerge = JSON.serialize( new MergeData(this.mergeAccFieldsMap, this.similarAccFieldsMap, this.fieldAPINameFieldLabelMap, mergeAccFieldsMap.keySet()) );

		return null;
	}

	public PageReference confirmMerge() {
		Map<String, String> fieldValueMap = (Map<String, String>)JSON.deserialize(jsonMergedValues, Map<String, String>.class);

		for  (String key : fieldValueMap.keySet()) {
			if ( String.isBlank(fieldValueMap.get(key)) ) {
				fieldValueMap.put(key, null);
			}
		}

		for (String fieldName : fieldValueMap.keySet()) {

			String valueType = fieldTypeMap.get(fieldName);

			if (valueType.equalsIgnoreCase('STRING')) {
				mergeAcc.put(fieldName,  fieldValueMap.get(fieldName));
				continue;
			}

			if (valueType.equalsIgnoreCase('DOUBLE')) {
				mergeAcc.put(fieldName, String.isBlank(fieldValueMap.get(fieldName)) ? null : Double.valueOf( fieldValueMap.get(fieldName) ) );
				continue;
			}

			if (valueType.equalsIgnoreCase('ID')) {
				mergeAcc.put(fieldName, String.isBlank(fieldValueMap.get(fieldName)) ? null : ID.valueOf( fieldValueMap.get(fieldName) ) );
				continue;
			}

			if (valueType.equalsIgnoreCase('BOOLEAN')) {
				mergeAcc.put(fieldName, String.isBlank(fieldValueMap.get(fieldName)) ? null : Boolean.valueOf( fieldValueMap.get(fieldName) ) );
				continue;
			}

			if (valueType.equalsIgnoreCase('INTEGER')) {
				mergeAcc.put(fieldName, String.isBlank(fieldValueMap.get(fieldName)) ? null : Integer.valueOf( fieldValueMap.get(fieldName) ) );
				continue;
			}

			if (valueType.equalsIgnoreCase('DATE')) {
				mergeAcc.put(fieldName, String.isBlank(fieldValueMap.get(fieldName)) ? null : Date.valueOf( fieldValueMap.get(fieldName) ) );
				continue;
			}

			if (valueType.equalsIgnoreCase('DATETIME')) {
				mergeAcc.put(fieldName, String.isBlank(fieldValueMap.get(fieldName)) ? null : Datetime.valueOf( fieldValueMap.get(fieldName) ) );
				continue;
			}
		}

		mergeAcc.isMergeable__c = false;


		Boolean isUpdateableAccount = Schema.getGlobalDescribe().get('Account').getDescribe().isMergeable() ? true : false;
		Schema.FieldSet fldSet = Schema.getGlobalDescribe().get('Account').getDescribe().fieldSets.getMap().get(amazonNamespacePrefix + 'Merge_Field_Set');
		Map<String, Schema.SObjectField> accountFieldsMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
		for (String fieldAPI : mergeFieldSet) {
			Schema.SObjectField objField = accountFieldsMap.get(fieldAPI);
			if ( !objField.getDescribe().isUpdateable() ) {
				isUpdateableAccount = false;
			}
		}
		isUpdateableAccount = Schema.sObjectType.Account.fields.isMergeable__c.isUpdateable() ? isUpdateableAccount : false;

		if(isUpdateableAccount) {
			update mergeAcc;
			merge mergeAcc similarAcc;
		}
		else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Insufficient priveleges.'));
			return null;
		}

		return new PageReference('/'+mergeAcc.Id);
	}

	public PageReference cancel() {
		return new PageReference('/'+mergeAcc.Id);
	}

	public PageReference cancelMerge() {
		AccNotSelected = true;
		displayPopup = false;
		return null;
	}

	public PageReference showPopup() {
		displayPopup = true;
		return null;
	}

	public PageReference cancelPopup() {
		displayPopup = false;
		return null;
	}

	public Set<String> getMergeFieldSetValues() {
		Set<String> fieldSetAPINames = new Set<String>();
		this.fieldAPINameFieldLabelMap = new Map<String, String>();

		Schema.FieldSet fldSet = Schema.getGlobalDescribe().get('Account').getDescribe().fieldSets.getMap().get(amazonNamespacePrefix + 'Merge_Field_Set');

		List<Schema.FieldSetMember> fldSetMembers = fldSet.getFields();

		Map<String, Schema.SObjectField> accountFieldsMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();

		Map<String, String> nonUpdateableFieldsMap = new Map<String, String>();
		Boolean isNonUpdadateable = false;
		for (Schema.FieldSetMember fsMember : fldSetMembers) {
			if (fsMember.getFieldPath() == 'Name') {
				continue;
			}

			Schema.SObjectField objField = accountFieldsMap.get(fsMember.getFieldPath());
			if (!objField.getDescribe().isCalculated() && objField.getDescribe().isUpdateable()) {
				fieldSetAPINames.add(fsMember.getFieldPath());
				this.fieldAPINameFieldLabelMap.put(fsMember.getFieldPath(),fsMember.getLabel());
			} 
			else {
				isNonUpdadateable = true;
				nonUpdateableFieldsMap.put(fsMember.getFieldPath(), fsMember.getLabel());
			}

			if (isNonUpdadateable) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'<b>Not all fields from fieldset are available for edit.</b>'));

				for (String fieldName : nonUpdateableFieldsMap.keySet() ) {
					String msg = fieldName + ' (<b>' + nonUpdateableFieldsMap.get(fieldName) + '</b>)';
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,msg));
				}
			}

			isConflictsToMerge = isNonUpdadateable;
		}
		return fieldSetAPINames;
	}



	public Map<String, String> getFieldSetTypes(Set<String> mergeFields) {
		Map<String, String> fieldTypeMap = new Map<String, String>();

		Map<String, Schema.SObjectField> accountFieldsMap = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();

		for (String fieldName : mergeFields) {
			fieldTypeMap.put(fieldName, accountFieldsMap.get(fieldName).getDescribe().getSOAPType().name());
		}
		return fieldTypeMap;
	}

	public String getSOQLvalue(String param) {
		return param == null ? '= null' : 'LIKE \'%' + param + '%\'';
	}

	public class MergeData {
		public Map<String, String> masterValues {get; set;}
		public Map<String, String> similarValues {get; set;}
		public Map<String, String> nameLabelMap {get; set;}

		public Set<String> fieldNames {get; set;}

		public MergeData(Map<String, String> masterMap, Map<String, String> similarMap, Map<String, String> labelMap, Set<String> fields) {
			this.masterValues = masterMap;
			this.similarValues = similarMap;
			this.nameLabelMap = labelMap;

			List<String> fieldsToSort = new List<String>(fields);
			fieldsToSort.sort();
			this.fieldNames = new Set<String>(fieldsToSort);
		}
	}
}