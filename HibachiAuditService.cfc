/*

    Slatwall - An Open Source eCommerce Platform
    Copyright (C) ten24, LLC
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
	
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
	
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    Linking this program statically or dynamically with other modules is
    making a combined work based on this program.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.
	
    As a special exception, the copyright holders of this program give you
    permission to combine this program with independent modules and your 
    custom code, regardless of the license terms of these independent
    modules, and to copy and distribute the resulting program under terms 
    of your choice, provided that you follow these specific guidelines: 

	- You also meet the terms and conditions of the license of each 
	  independent module 
	- You must not alter the default display of the Slatwall name or logo from  
	  any part of the application 
	- Your custom code must not alter or create any files inside Slatwall, 
	  except in the following directories:
		/integrationServices/

	You may copy and distribute the modified version of this program that meets 
	the above guidelines as a combined work under the terms of GPL for this program, 
	provided that you include the source code of that other code when and as the 
	GNU GPL requires distribution of source code.
    
    If you modify this program, you may extend this exception to your version 
    of the program, but you are not obligated to do so.

Notes:

*/

component extends="HibachiService" accessors="true" {
	
	// ===================== START: Logical Methods ===========================
	public any function getRelatedEntityForAudit(any audit) {
		// TODO What if the entity has been deleted? Or perhaps all of the prior related audit logs shouldn't even exist so this would never be a problem?
		return getServiceByEntityName(arguments.audit.getBaseObject()).invokeMethod("get#arguments.audit.getBaseObject()#", {1=arguments.audit.getBaseID()});
	}
	
	public any function newAudit() {
		var audit = super.newAudit();
		audit.setAuditDateTime(now());
		audit.setIPAddress(CGI.REMOTE_ADDR);
		if(!getHibachiScope().getAccount().isNew() && getHibachiScope().getAccount().getAdminAccountFlag() ){
			audit.setSessionAccount( getHibachiScope().getAccount() );	
		}
		
		return audit;
	}
	
	public void function logAccountActivity(string auditType) {
		if (listFindNoCase("login,logout", arguments.auditType)) {
			var audit = this.newAudit();
			audit.setAuditType(arguments.auditType);
			this.saveAudit(audit);
		}
	}
	
	public void function logEntityDelete(any entity) {
		var audit = this.newAudit();
		audit.setAuditType("delete");
		audit.setBaseID(arguments.entity.getPrimaryIDValue());
		audit.setBaseObject(arguments.entity.getClassName());
		this.saveAudit(audit);
	}
	
	public any function logEntityModify(any entity, struct oldData) {
		if (arguments.entity.getAuditableFlag()) {
			var audit = this.newAudit();
			audit.setBaseID(entity.getPrimaryIDValue());
			audit.setBaseObject(entity.getClassName());
			
			// Audit type is create when no old data available or no previous audit log data available
			if (isNull(arguments.oldData) || (arguments.entity.getAuditSmartList().getRecordsCount()  == 0)) {
				audit.setAuditType("create");
				
				// Remove oldData from arguments if it was provided because it is not applicable for property change data
				if (!isNull(arguments.oldData)) {
					structDelete(arguments, "oldData");
				}
			// Audit type is update
			} else {
				audit.setAuditType("update");
			}
			
			audit.setData(serializeJSON(generatePropertyChangeDataForEntity(argumentCollection=arguments)));
			this.saveAudit(audit);
		}
	}
	
	public struct function generatePropertyChangeDataForEntity(any entity, struct oldData) {		
		// Note: The new and old property value mapping data structs used below effectively allow us to make linear comparisons
		// To reduce the complexity of comparing the new and old nested property values, we simplify the process by flattening out the entire property
		// structure using a single-level struct with matching keys that are used to map the respective property values of new and old data.
		// We can then determine the "deltas" by performing a linear simple value comparisons using the key/value pairs in the property value mapping data structs
		
		var auditablePropertiesStruct = arguments.entity.getAuditablePropertiesStruct();
		
		// Holds the actual property values that will be serialized as JSON when persisted to the database
		var propertyChangeData = {};
		propertyChangeData["newPropertyData"] = {};
		
		var newPropertyValueMappingData = {};
		// Track all new auditable properties initially
		for (var propertyName in auditablePropertiesStruct) {
			propertyChangeData.newPropertyData[propertyName] = getStandardizedValue(propertyValue=entity.invokeMethod("get#propertyName#"), mappingData=newPropertyValueMappingData, mappingPath=propertyName);
		}
		
		var oldPropertyValueMappingData = {};
		// Track all old auditable properties initially
		if (!isNull(arguments.oldData)) {
			propertyChangeData["oldPropertyData"] = {};
			for (var propertyName in auditablePropertiesStruct) {
				if (structKeyExists(arguments.oldData, propertyName)) {
					propertyChangeData.oldPropertyData[propertyName] = getStandardizedValue(propertyValue=arguments.oldData[propertyName], mappingData=oldPropertyValueMappingData, mappingPath=propertyName);
					
					// Immediately delete empty value because it is irrelevant
					if (isSimpleValue(propertyChangeData.oldPropertyData[propertyName]) && !len(propertyChangeData.oldPropertyData[propertyName])) {
						structDelete(propertyChangeData.oldPropertyData, propertyName);
					}
				}
			}
		}
		
		// Note: If oldPropertyData has been populated, propertyChangeData.oldPropertyData should not contain any empty property values
		
		// Further process new property values to filter out any empty values under certain conditions
		for (var propertyName in propertyChangeData.newPropertyData) {
			var newPropertyValue = propertyChangeData.newPropertyData[propertyName];
			
			// Keep new empty values only when they differ from their respective old non-empty values
			if (isSimpleValue(newPropertyValue) && !len(newPropertyValue)) {
				// Filter out new empty value because it is irrelevant since no old version of the value existed
				if (isNull(arguments.oldData) || !structKeyExists(propertyChangeData.oldPropertyData, propertyName)) {
					structDelete(propertyChangeData.newPropertyData, propertyName);
				}
			}
		}
		
		// NOTE: All empty arrays, structs, and null values in the property change data should have been converted to empty strings during standardization
		// Create a union of changed properties by complete 2-way comparisons of both new and old property value mapping data
		var changedPropertyNames = [];
		
		// Compare new against old
		for (var propertyValueMappingKey in newPropertyValueMappingData) {
			// Derive top level property name based on property value mapping key
			var matchResult = reMatchNoCase("(\S+?)(\b)", propertyValueMappingKey);
			var topLevelPropertyName = matchResult[1];
			
			// Skip unecessary comparison because property is already known to differ
			if (!arrayContains(changedPropertyNames, topLevelPropertyName)) {
				// Change detected by default because only new data contains property value or if new/old values differ
				if (!structKeyExists(oldPropertyValueMappingData, propertyValueMappingKey) || (newPropertyValueMappingData[propertyValueMappingKey] != oldPropertyValueMappingData[propertyValueMappingKey])) {
					if (len(newPropertyValueMappingData[propertyValueMappingKey])) {
						arrayAppend(changedPropertyNames, topLevelPropertyName);
					}
				}
			}
		}
		
		// Compare old against new
		if (!isNull(arguments.oldData)) {
			for (var propertyValueMappingKey in oldPropertyValueMappingData) {
				// Derive top level property name based on property value mapping key
				var matchResult = reMatchNoCase("(\S+?)(\b)", propertyValueMappingKey);
				var topLevelPropertyName = matchResult[1];
				
				// Skip unecessary comparison because property is already known to differ
				if (!arrayContains(changedPropertyNames, topLevelPropertyName)) {
					// Change detected by default because only old data contains property value or if new/old values differ
					if (!structKeyExists(newPropertyValueMappingData, propertyValueMappingKey) || (newPropertyValueMappingData[propertyValueMappingKey] != oldPropertyValueMappingData[propertyValueMappingKey])) {
						if (len(oldPropertyValueMappingData[propertyValueMappingKey])) {
							arrayAppend(changedPropertyNames, topLevelPropertyName);
						}
					}
				}
			}
		}
		
		// Remove all irrelevant property values from new property change data
		for (var propertyName in propertyChangeData.newPropertyData) {
			if (!arrayContains(changedPropertyNames, propertyName)) {
				structDelete(propertyChangeData.newPropertyData, propertyName);
			}
		}
		
		// Remove all irrelevant property values from old property change data
		if (!isNull(arguments.oldData)) {
			for (var propertyName in propertyChangeData.oldPropertyData) {
				if (!arrayContains(changedPropertyNames, propertyName)) {
					structDelete(propertyChangeData.oldPropertyData, propertyName);
				}
			}
		}
		
		return propertyChangeData;
	}
	
	public any function getStandardizedValue(any propertyValue, struct mappingData, string mappingPath="") {
		var standardizedValue = "";
		
		// Convert undefined or null property value to empty string
		if (!isDefined("arguments.propertyValue") || isNull(arguments.propertyValue)) {
			arguments.propertyValue = "";
		}
		
		// Simple Value
		if (isSimpleValue(arguments.propertyValue)) {
			standardizedValue = arguments.propertyValue;
			
			// Updates mapping data
			structInsert(arguments.mappingData, "#arguments.mappingPath#", standardizedValue, true);
		// Entity
		} else if (isObject(arguments.propertyValue) && arguments.propertyValue.isPersistent()) {
			standardizedValue = {};
			// Primary ID of entity is only relevant value
			standardizedValue["#arguments.propertyValue.getPrimaryIDPropertyName()#"] = arguments.propertyValue.getPrimaryIDValue();
			
			// Updates mapping data
			structInsert(arguments.mappingData, "#arguments.mappingPath#[#arguments.propertyValue.getPrimaryIDPropertyName()#]", standardizedValue["#arguments.propertyValue.getPrimaryIDPropertyName()#"], true);
		
		}
		/*
		// Array
		} else if (isArray(arguments.propertyValue)) {
			// Standardize values of all array items
			standardizedValue = [];
			for (var i = 1; i <= arraylen(arguments.propertyValue); i++) {
				arrayAppend(standardizedValue, getStandardizedValue(propertyValue=arguments.propertyValue[i], mappingData=arguments.mappingData, mappingPath="#arguments.mappingPath#[#i#]"));
			}
			
			// Convert empty array to emtpy string
			if (arrayIsEmpty(standardizedValue)) {
				standardizedValue = "";
			}
		// Struct
		} else if (isStruct(arguments.propertyValue)) {
			standardizedValue = {};
			
			for (var key in arguments.propertyValue) {
				// Convert undefined values to empty string because null values could have been inserted into struct
				if (!isDefined("arguments.propertyValue.#key#") || isNull(arguments.propertyValue[key])) {
					arguments.propertyValue[key] = "";
				}
				
				// Standardize all key/value pairs
				standardizedValue[key] = getStandardizedValue(propertyValue=arguments.propertyValue[key], mappingData=arguments.mappingData, mappingPath="#arguments.mappingPath#[#key#]");
			}
			
			// Convert empty struct to empty string
			if (structIsEmpty(standardizedValue)) {
				standardizedValue = "";
			}
		}
		*/
		
		return standardizedValue;
	}
	
	// =====================  END: Logical Methods ============================
	
	// ===================== START: DAO Passthrough ===========================
	
	// ===================== START: DAO Passthrough ===========================
	
	// ===================== START: Process Methods ===========================
	
	public any function processAudit_rollback(required any audit, required any processObject) {
		// TODO implement processAudit_rollback method
		// determine which entity audit corresponds to
		// grab entity's audit log
		// inspect processing object to determine which audit entry to rollback to
		// calculate the changes for rollback
		// call populate on entity and save
		throw(message="We are rolling back to '#arguments.processObject.getRollbackAudit().getAuditID()#'.");
	}
	
	// =====================  END: Process Methods ============================
	
	// ====================== START: Status Methods ===========================
	
	// ======================  END: Status Methods ============================
	
	// ====================== START: Save Overrides ===========================
	
	// ======================  END: Save Overrides ============================
	
	// ==================== START: Smart List Overrides =======================
	
	// ====================  END: Smart List Overrides ========================
	
	// ====================== START: Get Overrides ============================
	
	// ======================  END: Get Overrides =============================
	
	// ===================== START: Delete Overrides ==========================
	
	// =====================  END: Delete Overrides ===========================
	
}