<cfoutput>
	<div class="svoutilitytoolbar">
		#view('admin:utility/toolbarsearch')#
		#view('admin:utility/campaignlink', args)#
		<ul class="MainMenu">
			<li class="MenuTop"></li>
			<li><a href="#buildURL(action='admin:main.dashboard')#">#rc.rbFactory.getKey("toolbar.dashboard")#</a></li>
			<li>
				<a href="#buildURL(action='admin:product.list')#">#rc.rbFactory.getKey("toolbar.products")#</a>
				<div class="MenuSubOne">
					<ul>
						<li><a href="#buildURL(action='admin:product.edit')#">#rc.rbFactory.getKey("toolbar.products.createnewproduct")#</a></li>
						<li><a href="#buildURL(action='admin:product.types')#">#rc.rbFactory.getKey("toolbar.products.producttypes")#</a></li>
						<li><a href="#buildURL(action='admin:product.list')#">Product Listing</a></li>
						<li><a href="#buildURL(action='admin:brand.edit')#">Create New Brand</a></li>
						<li><a href="#buildURL(action='admin:brand.list')#">Brand Listing</a></li>
					</ul>
				</div>
			</li>
			<li>
				<a href="##">Help</a>
				<div class="MenuSubOne">
					<ul>
						<li><a href="#buildURL(action='admin:help.about')#">About</a></li>
					</ul>
				</div>
			</li>
			<li class="MenuBottom"></li>
		</ul>
		<ul class="MainToolbar">
			<li class="LogoSearch">
				<img src="/plugins/#getPluginConfig().getDirectory()#/images/toolbar/toolbar_logo.png" />
				<form name="ToolbarSearch" method="post" onKeyup="toolbarSearchKeyup(this);" onSubmit="return slatwallAjaxFormSubmit(this);">
					<input type="hidden" name="action" value="admin:utility.toolbarsearch" />
					<input type="text" name="ToolbarKeyword" class="AdminSearch" />
				</form>
			</li>
			<li><a href="http://#cgi.http_host#/">Website</a></li>
			<cfif isDefined('request.contentBean')>
				<li><a href="javascript:;" onClick="doSlatAction('utility.campaignlink',{'Show': 1, 'LandingPageContentID': '#request.contentBean.getContentID()#', 'QueryString': '#cgi.query_string#'})">Campaign Link</a></li>
			</cfif>
			<cfif isDefined('request.muraScope.slatwall.Product')>
				<li><a href="#buildURL(action='admin:product.detail', querystring='ProductID=#request.muraScope.slatwall.Product.getProductID()#')#">Product Detail</a></li>
			</cfif>
		</ul>
	</div>
</cfoutput>