#Adaware Comand Line Scanner
function Update-AdAware {
    [CmdletBinding()]
    param()
    
    $InstallPath = "C:\Program Files\AdAware"
    
    if(Test-Path "$InstallPath\AdAwareCommandLineScanner.exe" ){
        Write-Verbose "Starting update"
        while($output -notcontains 'Definitions up to date'){
            $output = cmd /c "$InstallPath\AdAwareCommandLineScanner.exe" --updatedefs 2`>`&1
        }
        Write-Verbose "Definitions up to date"
    }
    else {
        Write-Output "Unable to find AdAware."
    }

        
}

function Upgrade-AdAware {
    [CmdletBinding()]
    param()
    
    $InstallPath = "C:\Program Files\AdAware"
   
    if(Test-Path "$InstallPath\AdAwareCommandLineScanner.exe" ){
        Write-Verbose "Starting upgrade"
        $output = cmd /c "$InstallPath\AdAwareCommandLineScanner.exe" --updateapp 2`>`&1          
        if($output -contains 'You have the latest version'){                
            Write-Verbose "Latest version installed."
            return
        }
        elseif($output -like "New version is available for downloading. Url:*"){
            $output = $($output[1] -replace 'New version is available for downloading. Url:','').trim()
            Write-Verbose "A new version is avalable."
            Write-Verbose "Removing old version."
            Remove-Item $InstallPath -Recurse -Force
            Install-AdAware -url $output
        }
        else{            
            Write-Output $output
        }
    }
    else {
        Write-Output "Unable to find AdAware."
    }        
}

function Install-AdAware{
    [CmdletBinding()]
    param(
        $url = 'http://downloadnada.lavasoft.com/update/11.15.1046.10613/x64/AdAwareCommandLineScanner.zip'
    )
    if(!$url){
        if ([System.IntPtr]::Size -eq 4) { 
            $url = 'http://downloadnada.lavasoft.com/update/11.15.1046.10613/win32/AdAwareCommandLineScanner.zip' 
        } 
        else { 
            $url = 'http://downloadnada.lavasoft.com/update/11.15.1046.10613/x64/AdAwareCommandLineScanner.zip' 
        }
    }
    $InstallPath = "C:\Program Files\AdAware"

    if(Test-Path "$InstallPath\AdAwareCommandLineScanner.exe" ){
        Write-Output "AdAware is already installed at, `"C:\Program Files\AdAware\AdAwareCommandLineScanner.exe`"" 
    }
    else {
        Write-Verbose "Downloading AdAware."
        $Output = "$env:temp\AdAwareCommandLineScanner.zip"
        (New-Object System.Net.WebClient).DownloadFile($url, $output)

        Write-Verbose "Unzipping"
        New-Item $InstallPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        $shell = new-object -com shell.application
        $zip = $shell.NameSpace($Output)
        foreach($item in $zip.items()) {
            $shell.Namespace('C:\Program Files\AdAware').copyhere($item, 0x14) 
        }
        if(Test-Path "$InstallPath\AdAwareCommandLineScanner.exe"){
            Write-Verbose "AdAware installed at, $InstallPath"
            Upgrade-AdAware
            Update-AdAware
        }
        else{
            Write-Error "There was an error installing AdAware."
        }
    }
    
}

function Scan-AdAware {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateSet('quick','full')]
        $Type,
        [ValidateSet('delete','quarantine','disinfect')]
        $Action,
        $LogPath,
        [switch]$Wait
    )
    $InstallPath = "C:\Program Files\AdAware"
    $Logname = $(get-date -uFormat "%m%d%Y%H%MS")

    $Arg = "--$Type"
    if($Action){
        $Arg += " --$Action"
    }
    if($LogPath){
        $Arg += " --scan-result `"$LogPath`""
    }

    
    if(Test-Path "$InstallPath\AdAwareCommandLineScanner.exe" ){
        Write-Verbose "Starting scan"
        $cmd = "$InstallPath\AdAwareCommandLineScanner.exe"
        Write-Verbose $Arg
        $Output = Start-Process -FilePath $cmd -ArgumentList $Arg -NoNewWindow -PassThru -Wait:$Wait        Write-Verbose "Scan complete. Wait: $Wait"
    }
    else {
        Write-Output "Unable to find AdAware."
    }        
}
