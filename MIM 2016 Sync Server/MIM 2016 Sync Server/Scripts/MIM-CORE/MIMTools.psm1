# Created by JefKaz
# Version 2015.07.08.01

<#
.Synopsis
   Creates a new SharePoint Farm to be used by the MIM Portal  - Step 1
.DESCRIPTION
   Creates the needed Databases for the SharePoint Central Admin for the Farm

.PARAMETER DatabaseServer
    The <Server>\<Instance> or SQL Alias of where the SharePoint content will be stored.

.PARAMETER ConfigDBName
    The Name of the Database to contain the SharePoint Configuration (Default: MIMSP_Config)

.PARAMETER AdminContentDBName
    The Name of the Database to contain the SharePoint Central Admin Content (Default: MIMSP_Admin_Content)

.PARAMETER FarmAccountName
    The AccountName used to run the SharePoint Farm (Ex. DOMAIN\USER)
.PARAMETER CentralAdminUrl
    The URL used to access the Central Admin Site on the farm
.PARAMETER PassPhrase
    The PassPhrase used to manage the Farm members
.PARAMETER CentralAdminPort
    The port of the Application in SharePoint (Default: 12345)
.PARAMETER UseCentralAdminSSL
    If selected the WebApp will be created on Port 443 and support SSL.  Certificates are still required to be setup in IIS.

.LINK
    http://www.harbar.net/articles/FIMPortal.aspx

.EXAMPLE
  fff

.NOTES
    This is a module that simplifies the steps originall published here by spence@harbar.net:
        

#>
function New-MIMSPFarm
{
    [CmdletBinding()]
 
    Param
    (
        
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $DatabaseServer= "SQL.SP",

   
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $ConfigDBName = ("MIMSP_Config_"+$env:computerName),


        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $AdminContentDBName = ("MIMSP_Admin_Content_"+$env:computerName),
       
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $FarmAccountName,
  
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $CentralAdminUrl,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String]
        $PassPhrase = "MIMFarm#2013",

		[Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String]
        $CentralAdminPort = "12345",

		[switch]
		$UseCentralAdminSSL

    )

    Begin
    {
        if(@(get-pssnapin | where-object {$_.Name -eq "Microsoft.SharePoint.PowerShell"} ).count -eq 0) {add-pssnapin Microsoft.SharePoint.PowerShell}
    
    }
    Process
    {
        $farmAccount = Get-Credential $farmAccountName
        $passphraseSecure = (ConvertTo-SecureString $passphrase -AsPlainText -force)

        Write-Verbose "Creating Configuration Database and Central Admin Content Database..."
        New-SPConfigurationDatabase -DatabaseServer $databaseServer -DatabaseName $ConfigDBName `
                                    -AdministrationContentDatabaseName $adminContentDBName `
                                    -Passphrase $passphraseSecure -FarmCredentials $farmAccount

        $spfarm = Get-SPFarm -ErrorAction SilentlyContinue -ErrorVariable err        
        if ($spfarm -eq $null -or $err) {
            throw "Unable to verify farm creation."
        }

 
        Write-Verbose "ACLing SharePoint Resources..."
        Initialize-SPResourceSecurity
    
        Write-Verbose "Installing Services ..."
        Install-SPService  
    
        Write-Verbose "Installing Features..."
        Install-SPFeature -AllExistingFeatures

        Write-Verbose "Creating Central Administration..."             
        If($UseCentralAdminSSL){$setPort = "443"}else{$setPort = $CentralAdminPort}         
        New-SPCentralAdministration -Port $setPort -WindowsAuthProvider NTLM
        
        Write-Verbose "Fixing CA IIS binding..."
        Set-SPCentralAdministration -Port $setPort -Confirm:$false

        Write-Verbose "Fixing Internal URL..."
        if($UseCentralAdminSSL){$service = "https"}else{$service = "http"}
		$setIdentity = ("{0}://{1}:{2}" -f $service,$env:COMPUTERNAME,$setport)
        Set-SPAlternateURL -Identity $setIdentity -Url $CentralAdminUrl

        Write-Verbose "Installing Help..."
        Install-SPHelpCollection -All       
    
        Write-Verbose "Installing Application Content..."
        Install-SPApplicationContent
 
        Write-Verbose "Farm Creation Done!"

    }
    End
    {
    }
}

<#
.Synopsis
   Join existing SharePoint Farm  - Step 1a
.DESCRIPTION
   Joins an existing SharePoint Farm
.PARAMETER DatabaseServer
    The <Server>\<Instance> or SQL Alias of where the SharePoint content will be stored.

.PARAMETER ConfigDBName
    The Name of the Database to contain the SharePoint Configuration (Default: MIMSP_Config)

.PARAMETER PassPhrase
    The PassPhrase used to manage the Farm members  (Default:  MIMFarm#2013)
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Join-MIMSPFarm
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
         [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $DatabaseServer= "SQL.SP",

   
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $ConfigDBName = ("MIMSP_Config_"+$env:computerName),

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [String]
        $PassPhrase = "MIMFarm#2013"
    )

    Begin
    {
        if(@(get-pssnapin | where-object {$_.Name -eq "Microsoft.SharePoint.PowerShell"} ).count -eq 0) {add-pssnapin Microsoft.SharePoint.PowerShell}
    
    }
    Process
    {


  
      
        Write-Verbose "Joining Farm..."
        
        Connect-SPConfigurationDatabase -DatabaseServer $databaseServer -DatabaseName $configDbName -Passphrase (ConvertTo-SecureString $passphrase -AsPlainText -Force)
        
        Install-SPHelpCollection -All
        Initialize-SPResourceSecurity
        Install-SPService
        Install-SPFeature -AllExistingFeatures
 
        Write-Verbose "Farm Join Complete!"


    }
    End
    {
    }
}



<#
.Synopsis
   Creates the SP Core Services to host MIM Portal -  Step 2
.DESCRIPTION
        -Starts the Service Instances for and creates Service Applications and Proxies:
            -State Service
            -Usage and Health Data Collection Service
.PARAMETER StateName
    The name of the State Service (Default: State Service)
.PARAMETER StateDBName
    The name of the Database that will contain the State Service (Default: MIMSP_StateService)
.PARAMETER UsageName
    The name of the Usage Server (Default: Usage and Health Data Collection Service)
.PARAMETER UsageDBName
    The Name of the database that will contain the Usage Data (Default: MIMSP_Usage)
.LINK
    http://www.harbar.net/articles/FIMPortal.aspx
.NOTES
    This is a module that simplifies the steps originall published here by spence@harbar.net:
        http://www.harbar.net/articles/FIMPortal.aspx
#>
function New-MIMSPCoreServices
{



    [CmdletBinding()]
    Param
    (
        
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $StateName = "State Service",

       [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $StateDBName = ("MIMSP_StateService_"+$env:computerName),

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]
        $UsageName = "Usage and Health Data Collection Service",

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [string]
        $UsageDBName = ("MIMSP_Usage_"+$env:computerName)
    )

    Begin
    {
        if(@(get-pssnapin | where-object {$_.Name -eq "Microsoft.SharePoint.PowerShell"} ).count -eq 0) {add-pssnapin Microsoft.SharePoint.PowerShell}
    
    }
    Process
    {


 
        # Create State Service Application and Proxy, add to Proxy Group
        Write-Verbose "Creating $stateName Application and Proxy..."
        $stateDB = New-SPStateServiceDatabase -Name $stateDBName
        $state = New-SPStateServiceApplication -Name $stateName -Database $stateDB
        $proxy = New-SPStateServiceApplicationProxy -Name "$stateName Proxy" -ServiceApplication $state -DefaultProxyGroup
 
 
        # Create Usage Service Application and Proxy, add to Proxy Group, and provision it's Proxy
        Write-Verbose "Creating $usageName Application and Proxy..."
        $serviceInstance = Get-SPUsageService
        New-SPUsageApplication -Name $usageName -DatabaseName $usageDBName -UsageService $serviceInstance
        $proxy = Get-SPServiceApplicationProxy | ? { $_.TypeName -eq "Usage and Health Data Collection Proxy" }
        $proxy.Provision();

 
        Write-Verbose "MIM SP Core Services done!"

    }
    End
    {
    }
}

<#
.Synopsis
   Creates the MIM Web Application to host MIM Portal -  Step 3
.DESCRIPTION
   Creates the Web Application to host the MIMPortal on the SharePoint Farm
        - Creates a new Managed Account
        - Creates a new classic mode SSL Web Application in a new Application Pool
        - Creates a root Site Collection using the blank site template

.PARAMETER AppPoolAccountName
    The Account used as the AppPool Identity for the MIM Portal (ex: DOMAIN\USER)
.PARAMETER AppPoolName
    The name of the AppPool in IIS (Default: SharePoint Content)
.PARAMETER PortalUrl
    The URL used to access the MIM Portal (ex: https://MIMportal.company.com)
.PARAMETER HostHeader
    The HostHeader used in IIS (ex: MIMportal.company.com)
.PARAMETER AppName
    The name of the Application in SharePoint (Default: MIM Portal)
.PARAMETER AppPort
    The port of the Application in SharePoint (Default: 80)
.PARAMETER UseSSLPort
    If selected the WebApp will be created on Port 443 and support SSL.  Certificates are still required to be setup in IIS.
.PARAMETER OwnerEmail
    The Email address of the site owner in SMTP format
.PARAMETER OwnerAccountName
    The AccountName of the Site owner (ex: DOMAIN\USER)
.PARAMETER ContentDBName
    The name of the Database that will hold the MIM Portal Content (Default: MIMSP_Content_Portal)
.LINK
    http://www.harbar.net/articles/FIMPortal.aspx
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.NOTES
    This is a module that simplifies the steps originally published here by spence@harbar.net:
        http://www.harbar.net/articles/FIMPortal.aspx
#>
function New-MIMSPWebApp
{


    [CmdletBinding()]
    Param
    (
        
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $AppPoolAccountName,
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $AppPoolName = "SharePoint Content",

       [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]
        $PortalUrl,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [string]
        $HostHeader,
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4)]
        [string]
        $AppName = "MIM Portal",

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=5)]
        [string]
        $OwnerEmail,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=6)]
        [string]
        $OwnerAccountName,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=7)]
        [string]
        $ContentDBName = ("MIMSP_Content_Portal_"+$env:computerName),
		[Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=8)]
		[string]
		$AppPort="80",
		[Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=9)]
		[switch]
		$UseAppSSL


    )

    Begin
    {
        if(@(get-pssnapin | where-object {$_.Name -eq "Microsoft.SharePoint.PowerShell"} ).count -eq 0) {add-pssnapin Microsoft.SharePoint.PowerShell}
    
    }
    Process
    {



        # Create Managed Account
        Write-Verbose "Please supply the password for the $AppPoolAccountName Account..."
        $appPoolCred = Get-Credential $AppPoolAccountName
        Write-Verbose "Creating Managed Account..."
        $AppPoolAccount = New-SPManagedAccount -Credential $appPoolCred
 
        # Create a new Web App in the default Proxy Group using Windows Classic on Port 80 with host header
        Write-Verbose "Creating Web Application..."

		if ($UseSSLPort)
		{
			 $webApp = New-SPWebApplication -ApplicationPool $AppPoolName -ApplicationPoolAccount $AppPoolAccountName -Name $AppName -Port 443 -SecureSocketsLayer:$true -AuthenticationMethod NTLM -HostHeader $hostHeader  -DatabaseName $contentDBName
		}
		else
		{
			 $webApp = New-SPWebApplication -ApplicationPool $AppPoolName -ApplicationPoolAccount $AppPoolAccountName -Name $AppName -Port $AppPort -SecureSocketsLayer:$false -AuthenticationMethod NTLM -HostHeader $hostHeader  -DatabaseName $contentDBName
		}
       
 
        # configure ViewState as MIM likes it
        Write-Host "Configuring View State..."
        $contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService;
        $contentService.ViewStateOnServer = $false;
        $contentService.Update();
 
        # Create a root Site Collection in 2010 mode
        Write-verbose "Creating root Site Collection..."
        New-SPSite -Url $PortalUrl -owneralias $ownerAccountName -ownerEmail $ownerEmail -Template "STS#1" -CompatibilityLevel 14

        Write-Verbose "Disabling self service upgrade..."
        $spSite = Get-SpSite($PortalUrl);
        $spSite.AllowSelfServiceUpgrade = $false
 

        Write-Verbose "Disabling SPTimer jobs!"
        Get-SPTimerJob hourly-all-sptimerservice-health-analysis-job | disable-SPTimerJob

        Write-Verbose "MIM SP Web Application done!"


    }
    End
    {
    }
}

<#
.Synopsis
   Enable Kerberos on SP Web App for MIM Portal
.DESCRIPTION
   Set the MIM Portal to use Kerberos authentication in SharePoint web application
.PARAMETER PortalURL
    The URL of the MIM Portal

.LINK
    http://www.harbar.net/articles/FIMPortal.aspx

.NOTES
    This is a module that simplifies the steps originall published here by spence@harbar.net:
        http://www.harbar.net/articles/FIMPortal.aspx

#>
function Set-MIMPortalKerberos
{
    [CmdletBinding()]

    Param
    (
        
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $PortalURL
    )

    Begin
    {
    }
    Process
    {

         


    Write-Verbose "Setting Kerberos for $PortalUrl"
    Set-SPWebApplication -Identity $PortalUrl -AuthenticationMethod Kerberos -Zone Default 
    Write-Verbose "Complete!"

    }
    End
    {
    }
}

<#
.Synopsis
   Sets the WelcomePage for default Site to MIM
.DESCRIPTION
   Sets the WelcomePage for default Site to MIM
.PARAMETER URL
    The Portal URL that is defined in SharePoint
.PARAMETER isWSS3
    Use this switch if you are using Windows SharePoint Service 3.0 which did not have PowerShell cmdlets
.EXAMPLE
   Set-MIMPortalRedirect "http://localhost"
.EXAMPLE
   Set-MIMPortalRedirect "http://MIMportal.company.com"
.LINK
    http://techtrainingnotes.blogspot.com/2011/06/sharepoint-how-to-change-default-home.html
.NOTES
    The contents of the default.aspx should be below, and should be placed in the c:\inetpub\wwwroot\wss\VirtualDirectories\80 directory
    <%@ Page Language="C#" %> 
    <script runat="server"> 
        protected override void OnLoad(EventArgs e) 
        { 
        base.OnLoad(e); 
        Response.Redirect("~/IdentityManagement/default.aspx"); 
        } 
    </script>

    You must be a farm/collection admin to run this command

    Originally adapted from http://techtrainingnotes.blogspot.com/2011/06/sharepoint-how-to-change-default-home.html


#>
function Set-MIMPortalRedirect
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # The Default Site for your Application  (NOT \IdentityManagement)
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $URL,
        [switch]
        $isWSS3

       
    )

    Begin
    {
		
    }
    Process
    {
        if ($isWSS3)
        {
            

            Write-Verbose "Using .NET to get Sharepoint..."
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
            $site = New-Object Microsoft.SharePoint.SPSite($URL)
            
        }
        else
        {
            Write-Verbose "Loading the SharePoint PowerShell Snapin..."

            if(@(get-pssnapin | where-object {$_.Name -eq "MIMAutomation"} ).count -eq 0) {Add-PSSnapin Microsoft.SharePoint.PowerShell}

            $site = Get-SPSite $URL
            

        }

        
            $web = $site.RootWeb
      
            $folder = $web.RootFolder
            Write-Verbose "Setting Welcome Page to Default.aspx"
            $currentWelcome = $folder.WelcomePage
            Write-Verbose "Previous Welcome Page was $currentWelcome"
            $folder.WelcomePage = "Default.aspx"
 
            $folder.update()
            $web.Dispose()
            $site.Dispose()


    }
    End
    {
    }
}

<#
.Synopsis
   QuickStart to install SP2013 Sp1 Portal on a Single Server to support MIM Portal
.DESCRIPTION
   QuickStart to install SP2013 Sp1 Portal on a Single Server to support MIM Portal
   Not to be used with mult-node farms.  Use manual install for that scenario
.PARAMETER DatabaseServer
    The <Server>\<Instance> or SQL Alias of where the SharePoint content will be stored.

.PARAMETER ConfigDBName
    The Name of the Database to contain the SharePoint Configuration (Default: MIMSP_Config)

.PARAMETER AdminContentDBName
    The Name of the Database to contain the SharePoint Central Admin Content (Default: MIMSP_Admin_Content)

.PARAMETER FarmAccountName
    The AccountName used to run the SharePoint Farm (Ex. DOMAIN\USER)
.PARAMETER CentralAdminUrl
    The URL used to access the Central Admin Site on the farm
.PARAMETER PassPhrase
    The PassPhrase used to manage the Farm members
.PARAMETER CentralAdminPort
    The port of the Application in SharePoint (Default: 12345)
.PARAMETER UseCentralAdminSSL
    If selected the WebApp will be created on Port 443 and support SSL.  Certificates are still required to be setup in IIS.
.PARAMETER StateName
    The name of the State Service (Default: State Service)
.PARAMETER StateDBName
    The name of the Database that will contain the State Service (Default: MIMSP_StateService)
.PARAMETER UsageName
    The name of the Usage Server (Default: Usage and Health Data Collection Service)
.PARAMETER UsageDBName
    The Name of the database that will contain the Usage Data (Default: MIMSP_Usage)
.PARAMETER AppPoolAccountName
    The Account used as the AppPool Identity for the MIM Portal (ex: DOMAIN\USER)
.PARAMETER AppPoolName
    The name of the AppPool in IIS (Default: SharePoint Content)
.PARAMETER PortalUrl
    The URL used to access the MIM Portal (ex: https://MIMportal.company.com)
.PARAMETER HostHeader
    The HostHeader used in IIS (ex: MIMportal.company.com)
.PARAMETER AppName
    The name of the Application in SharePoint (Default: MIM Portal)
.PARAMETER AppPort
    The port of the Application in SharePoint (Default: 80)
.PARAMETER UseSSLPort
    If selected the WebApp will be created on Port 443 and support SSL.  Certificates are still required to be setup in IIS.
.PARAMETER OwnerEmail
    The Email address of the site owner in SMTP format
.PARAMETER OwnerAccountName
    The AccountName of the Site owner (ex: DOMAIN\USER)
.PARAMETER ContentDBName
    The name of the Database that will hold the MIM Portal Content (Default: MIMSP_Content_Portal)
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function New-MIMPortalQuickStart
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
       [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $DatabaseServer= "SQL.SP",

   
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $ConfigDBName = ("MIMSP_Config_"+$env:computerName),


        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $AdminContentDBName = ("MIMSP_Admin_Content_"+$env:computerName),
       
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $FarmAccountName,
  
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $CentralAdminUrl,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String]
        $PassPhrase = "MIMFarm#2013",

		[Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String]
        $CentralAdminPort = "12345",

		[switch]
		$UseCentralAdminSSL,

		[Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $StateName = "State Service",

       [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $StateDBName = ("MIMSP_StateService_"+$env:computerName),

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]
        $UsageName = "Usage and Health Data Collection Service",

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [string]
        $UsageDBName = ("MIMSP_Usage_"+$env:computerName),

		 [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $AppPoolAccountName,
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $AppPoolName = "SharePoint Content",

       [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string]
        $PortalUrl,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [string]
        $HostHeader,
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4)]
        [string]
        $AppName = "MIM Portal",

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=5)]
        [string]
        $OwnerEmail,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=6)]
        [string]
        $OwnerAccountName,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=7)]
        [string]
        $ContentDBName = ("MIMSP_Content_Portal_"+$env:computerName),
		[Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=8)]
		[string]
		$AppPort="80",
		[switch]
		$UseAppSSL
    )

    Begin
    {
    }
    Process
    {
		Write-Host "Configuring SharePoint Foundation 2013 SP1 to support the MIM Portal!" -ForegroundColor Green
		
		Write-Host "Beginning Step 1 - Base Farm Creation...." -ForegroundColor Green
		New-MIMSPFarm -DatabaseServer $DatabaseServer -ConfigDBName $ConfigDBName -AdminContentDBName $AdminContentDBName -FarmAccountName $FarmAccountName -CentralAdminUrl $CentralAdminUrl -CentralAdminPort $CentralAdminPort -PassPhrase $PassPhrase
		Write-Host "Ending Step 1 - Base Farm Creation...." -ForegroundColor DarkGreen

		Write-Host "Beginning Step 2 - MIM Portal Core Services Creation..." -ForegroundColor Green
		New-MIMSPCoreServices -StateName $StateName -StateDBName $StateDBName -UsageName $UsageName -UsageDBName $UsageDBName
		Write-Host "Ending Step 2 - MIM Portal Core Services Creation..." -ForegroundColor DarkGreen

		Write-Host "Beginning Step 3 - MIM Portal Web App Creation..." -ForegroundColor Green
		New-MIMSPWebApp -AppPoolAccountName $AppPoolAccountName -AppPoolName $AppPoolName -PortalUrl $PortalUrl -HostHeader $HostHeader -AppName $AppName -AppPort $AppPort -OwnerEmail $OwnerEmail -OwnerAccountName $OwnerAccountName -ContentDBName $ContentDBName
		Write-Host "Ending Step 3 - MIM Portal Web App Creation..." -ForegroundColor DarkGreen

		Write-Host "Beginning Step 4 - MIM Portal Enabling Kerberos on Portal..." -ForegroundColor Green
		Set-MIMPortalKerberos -PortalURL $PortalUrl
		Write-Host "Ending Step 4 - MIM Portal Enabling Kerberos on Portal..." -ForegroundColor DarkGreen

        Write-Host "Begining Step 5 - Enabling useAppPoolCredentials for MIM Portal in IIS..." -ForegroundColor Green
        Enable-MIMPortalUseAppPoolCreds
        Write-Host "Ending Step 5 - Enabling useAppPoolCredentials for MIM Portal in IIS..." -ForegroundColor DarkGreen
	}
    End
    {
		Write-Host ("Configuration Complete! Verify Portal at {0} opens as expected and then proceed with MIM Portal install!" -f $PortalUrl) -ForegroundColor Cyan
    }
}

<#
.Synopsis
   Set UseAppPoolCredentials to True for MIMPortal
.DESCRIPTION
  Set UseAppPoolCredentials to True for MIMPortal
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Enable-MIMPortalUseAppPoolCreds
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        
    )

    Begin
    {
    }
    Process
    {
        Write-Verbose "Getting Current UseappPoolCredentials Setting"
        Get-WebConfigurationProperty -Filter /system.webServer/security/authentication/windowsAuthentication -Name useAppPoolCredentials
        Write-Verbose "Setting new UseAppPoolCredentials Setting to True"
        set-WebConfigurationProperty -Filter /system.webServer/security/authentication/windowsAuthentication -Name useAppPoolCredentials -Value true
    }
    End
    {
        Write-Verbose "Complete!"
    }
}