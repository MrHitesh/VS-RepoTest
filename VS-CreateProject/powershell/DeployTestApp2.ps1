	import-module webadministration

	$BuildNumber=$Env:BUILD_NUMBER
	$AppName=$Env:JOB_NAME
	$SiteFolderPath="C:\inetpub\wwwroot\TestApp2"
	$SiteFolderPathWithEscape="C:\\inetpub\\wwwroot\\TestApp2\\"
	$JenkinsWorkspace="C:\\Program Files (x86)\\Jenkins\\workspace"
    $website="Default Web Site"
	$ManagedPipelineMode="Integrated"
	$ManagedRuntimeVersion="v4.0"
	$Enable32= $false
	$IdentityType="NetworkService"
	
	
	if(Test-Path IIS:\AppPools\$AppName)
	{
	"AppPool already Exists, deleting the AppPool"
	$manager = Get-IISServerManager
	$manager.ApplicationPools[$AppName].Delete()
	$manager.CommitChanges()
	}
	
	"Creating new app pool with provided configurations"
	$manager = Get-IISServerManager
	$pool = $manager.ApplicationPools.Add($AppName)
	$pool.ManagedPipelineMode = $ManagedPipelineMode
	$pool.ManagedRuntimeVersion = $ManagedRuntimeVersion
	$pool.Enable32BitAppOnWin64 = $Enable32
	$pool.AutoStart = $true
	$pool.StartMode = "OnDemand"
	$pool.ProcessModel.IdentityType = $IdentityType
	$manager.CommitChanges()
	"App pool created succesfully"
	
	if ((Get-WebApplication -Name $AppName) -eq $null) {
	"Creating Application on IIS"
	New-Item -Type Application -Path "IIS:\Sites\$website\$AppName" -physicalPath $SiteFolderPath
	Write-Host "$AppName application created"
	}
	else
	{
	Write-Host "$AppName application already Exists"
	}
	
	Write-Host "Assigning App Pool: $AppName to Application : $AppName"
	Set-ItemProperty -Path "IIS:\Sites\$website\$AppName" -name "applicationPool" -value $AppName
	
	
	#  Anonymous: system.webServer/security/authentication/anonymousAuthentication
	#  Basic:     system.webServer/security/authentication/basicAuthentication
	#  Windows:   system.webServer/security/authentication/windowsAuthentication
	Write-Host "Setting application authentication as Windows Authenticated"
	Set-WebConfigurationProperty `
    -Filter "/system.webServer/security/authentication/windowsAuthentication" `
    -Name "enabled" `
    -Value $true `
    -Location "$website/$AppName" `
    -PSPath IIS:\    # We are using the root (applicationHost.config) file

	
	$env:Path="C:\Program Files (x86)\jfrog"

	echo "setting config to use artifactory"
	jfrog rt c jenkins-server-1 --url=http://localhost:8081/artifactory/ --apikey=AKCp5bBNL65PgEJz1ZKE8LMxv1V2NwHJqkFpLiVSCsmRjdr4wPjUuVRHhZRqNspGsd1k64tS3
	jfrog rt use jenkins-server-1
	
	frog rt download msbuild-local/MsbuildLibrary/bin/Debug/MsbuildLibrary.dll dependencies\ --flat=true --build-name=$AppName --build-number=$BuildNumber
	jfrog rt upload $SiteFolderPathWithEscape msbuild-local/$AppName/ --flat=false --build-name=$AppName --build-number=$BuildNumber
	jfrog rt bce $AppName $BuildNumber
	jfrog rt bag $AppName $BuildNumber "$JenkinsWorkspace/$AppName"
	jfrog rt build-publish $AppName $BuildNumber
	
	
	
	
	
#C:\Users\Hitesh\Downloads\software\jfrog.exe rt c rt-server-1 --url=http://localhost:8081/artifactory --user=admin --password=admin
	
#C:\Users\Hitesh\Downloads\software\jfrog.exe rt use rt-server-1

#C:\Users\Hitesh\Downloads\software\jfrog.exe rt upload bin\\ msbuild-local/SimpleWebApplication/ --flat=false --build-name=SimpleWebApplication --build-number=636701083926556180 
	
	
	
	
	
	
	
	
	# Stop the app pool before changing the settings
	
	# if ((Get-WebAppPoolState -name $AppName).value -ne 'Stopped') {
	
			# Stop-WebAppPool -Name $AppName
			# Write-Host "app pool stopped"
		 # } 
		 
		 # Write-Host "creating application"
		 # if ((Get-WebApplication -Name $AppName) -eq $null) {
	
		# New-WebApplication -Name $AppName -Site 'Default Web Site' -PhysicalPath $SiteFolderPath -ApplicationPool $AppName
		# Write-Host "$AppName application created"
		# }
		# else
		# {
		# Write-Host "$AppName application already exists"
		# }
		
		# Check if application pool is already started
		# if ((Get-WebAppPoolState -name $AppName).value -ne 'Started') {
			# Start-WebAppPool -Name $AppName
			# Write-Host "starting the app pool"
		 # }

