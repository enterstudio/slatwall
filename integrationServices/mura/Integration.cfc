/*

    Slatwall - An Open Source eCommerce Platform
    Copyright (C) 2011 ten24, LLC

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
    
    Linking this library statically or dynamically with other modules is
    making a combined work based on this library.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.
 
    As a special exception, the copyright holders of this library give you
    permission to link this library with independent modules to produce an
    executable, regardless of the license terms of these independent
    modules, and to copy and distribute the resulting executable under
    terms of your choice, provided that you also meet, for each linked
    independent module, the terms and conditions of the license of that
    module.  An independent module is a module which is not derived from
    or based on this library.  If you modify this library, you may extend
    this exception to your version of the library, but you are not
    obligated to do so.  If you do not wish to do so, delete this
    exception statement from your version.

Notes:

*/
component accessors="true" output="false" extends="Slatwall.integrationServices.BaseIntegration" implements="Slatwall.integrationServices.IntegrationInterface" {
	
	public string function getIntegrationTypes() {
		return "authentication,fw1";
	}
	
	public string function getDisplayName() {
		return "Mura";
	}
	
	public struct function getSettings() {
		return {
			accountSyncType = {fieldType="select", valueOptions=[
				{name="Mura System Users Only",value="systemUserOnly"},
				{name="Mura Site Members Only",value="siteUserOnly"},
				{name="All Users",value="all"},
				{name="None",value="none"}
			]},
			createDefaultPages = {fieldType="yesno", defaultValue=1},
			superUserSyncFlag = {fieldType="yesno", defaultValue=1},
			legacyInjectFlag = {fieldType="yesno", defaultValue=0},
			legacyShoppingCart = {fieldType="text", defaultValue="shopping-cart"},
			legacyOrderStatus = {fieldType="text", defaultValue="order-status"},
			legacyOrderConfirmation = {fieldType="text", defaultValue="order-confirmation"},
			legacyMyAccount = {fieldType="text", defaultValue="my-account"},
			legacyCreateAccount = {fieldType="text", defaultValue="create-account"},
			legacyCheckout = {fieldType="text", defaultValue="checkout"}
		};
	}
	
	public array function getEventHandlers() {
		return ["Slatwall.integrationServices.mura.model.handler.SlatwallEventHandler"];
	}
	
	public string function getAdminNavbarHTML() {
		return '<a href="/admin" class="brand" style="margin-left:-10px;"><img src="#request.slatwallScope.getSlatwallRootPath()#/assets/images/mura.logo.png" style="width:25px;heigh:26px;" title="Mura" /></a>';
	}
	
}