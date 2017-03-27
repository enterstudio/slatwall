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
component extends="HibachiService" persistent="false" accessors="true" output="false" {

	// ===================== START: Logical Methods ===========================
	
	public string function getAllActiveFulfillmentMethodIDList() {
		var returnList = "";
		var apmSL = this.getFulfillmentMethodSmartList();
		apmSL.addFilter('activeFlag', 1);
		apmSL.addSelect('fulfillmentMethodID', 'fulfillmentMethodID');
		var records = apmSL.getRecords();
		for(var i=1; i<=arrayLen(records); i++) {
			returnList = listAppend(returnList, records[i]['fulfillmentMethodID']);
		}
		return returnList;
	}
	
	// =====================  END: Logical Methods ============================
	
	// ===================== START: DAO Passthrough ===========================
	
	// ===================== START: DAO Passthrough ===========================
	
	// ===================== START: Process Methods ===========================
	// Process: FulfillmentBatch
	public any function processFulfillmentBatch_create(required any fulfillmentBatch, required any processObject){
		
		//populate the fulfillmentbatch with the process data
		if (isNull(fulfillmentBatch.getAssignedAccount())){
			arguments.fulfillmentBatch.setAssignedAccount(processObject.getAssignedAccount());
		}
		
		if (!arrayLen(fulfillmentBatch.getLocations())){
			var location = processObject.getLocation();
			if (!isNull(location)){
				arguments.fulfillmentBatch.addLocation(location);
			}
		}
		
		if (isNull(fulfillmentBatch.getDescription())){
			arguments.fulfillmentBatch.setDescription(processObject.getDescription());
		}
		
		//If they are trying to pass fulfillments for the fulfillment batch.
		if (!isNull(processObject.getOrderFulfillmentIDList())){
			arguments.fulfillmentBatch.setFulfillmentBatchItems(arguments.processObject.getFulfillmentBatchItemsByOrderFulfillmentIDList());
		}
		
		//If they are trying to pass orderItems for the fulfillment batch.
		if (!isNull(processObject.getOrderItemIDList())){
			arguments.fulfillmentBatch.setFulfillmentBatchItems(arguments.processObject.getFulfillmentBatchItemsByOrderItemIDList());
		}
		
		return arguments.fulfillmentBatch;
	}
	
	// Stub: FulfillmentBatch Auto fulfill all fulfillment batch items
	public any function autoFulfill(required any fulfillmentBatch){
		
		var fulfillmentBatchItems = fulfillmentBatch.getFulfillmentBatchItems();
		for (var fulfillmentbatchItem in fulfillmentBatchItems){
			//fulfill.
		}
		return processObject.getFulfillmentBatch();
	}
	// =====================  END: Process Methods ============================
	
	// ====================== START: Save Overrides ===========================
	
	// ======================  END: Save Overrides ============================
	
	// ==================== START: Smart List Overrides =======================
	
	// ====================  END: Smart List Overrides ========================
	
	// ====================== START: Get Overrides ============================
	
	// ======================  END: Get Overrides =============================

}
