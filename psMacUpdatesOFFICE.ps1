<#
    .Synopsis
    Download MAU update for mac
    .DESCRIPTION
    Authors - Adam Martin, David Coupe
    Based on Bash script by pbowden@microsoft.com
    Needs to run as administator to allow file rights
    Creates directory structure for iis 
    Downloads updates to tempory structure
    Delets original files from iis
    moves new downloads to IIS structure
    .PARAMETER Channel
    Must supply channel. Values accaptable are "Production", "External", "InsiderFast"
    .PARAMETER IISRoot
    Must supply iisBase. The path to default IIS eg C:\inetpub\wwwroot
    .PARAMETER IisFolder
    Must supply channel. The Folder name of the Share to publish in iis. Eg MAUCache
    .PARAMETER Channel
    Must supply TempShare. Path For working folder. Everything is downloaded then moved from this location. Eg c:\temp
    .EXAMPLE
    powershell.exe .\psMacUpdatesOFFICE.ps1 -channel Production -IISRoot C:\inetpub\wwwroot -IisFolder maucache -TempShare C:\temp
    .EXAMPLE
    powershell.exe .\psMacUpdatesOFFICE.ps1 -channel Production -IISRoot C:\inetpub\wwwroot -IisFolder maucache -TempShare C:\temp -verbose
 #>
 [cmdletbinding()]
  Param(
  [Parameter(Mandatory=$true,HelpMessage='Must supply channel. Values accaptable are "Production", "External", "InsiderFast"')]
  [ValidateSet("Production", "External", "InsiderFast")]
  [string]
  $channel,
  [Parameter(Mandatory=$true,HelpMessage='Default IIS LOcation EG c:\iinetpub\wwwroot')]
  [Validatescript({if (test-path ($_)){$true} Else {Throw "$_ doesnt exist. Must be a valid Path"}})]
  [string]
  $IISRoot,
  [Parameter(Mandatory=$true,HelpMessage='IIS Shared Folder Name. Also used in the temp folder eg. MAUCache')]
  [string]
  $IisFolder,
  [Parameter(Mandatory=$true,HelpMessage='Path to Temp working space eg c:\temp')]
  [Validatescript({if (test-path ($_)){$true} Else {Throw "$_ doesnt exist. Must be a valid Path"}})]
  [string]
  $TempShare
)

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}


$null = New-Object System.Net.webclient

#$PublishFolderName = "MAUCache"
#$publishBasePath = "C:\inetpub\wwwroot"
#$tempfolderLocation = "C:\temp"

$PublishFolderName = $IisFolder
$publishBasePath = $IISRoot
$tempfolderLocation = $TempShare

#Test iis shared folder exists if not make it
if (!(test-path "$publishBasePath\$PublishFolderName")){
  New-Item -ItemType Directory -Path "$publishBasePath" -Name "$PublishFolderName"
  }


$PublishFolder = "$publishBasePath\$PublishFolderName"
$tempFolder = "$tempfolderLocation\$PublishFolderName"

$collarteralFolder = $tempFolder

#setup TEmp environment
If (Test-path -Path $tempFolder)
{
  Remove-Item $tempfolder -Recurse -Force

}
#Create TEmp Structure
  New-Item -ItemType Directory -Path $tempfolderlocation -Name "$PublishFolderName" 
  New-Item -ItemType Directory -Path "$tempfolder" -Name "Collateral"
  
  
  $starturl = "https://officecdn-microsoft-com.akamaized.net"
switch ($channel)
{
  "Production"{$webUrlDownload = "$starturl/pr/C1297A47-86C4-4C1F-97FA-950631F94777/OfficeMac/"}
  "External"{$webUrlDownload = "$starturl/pr/1ac37578-5a24-40fb-892e-b89d85b6dfaa/OfficeMac/"}
  "InsiderFast"{$webUrlDownload = "$starturl/pr/4B2D7701-0A4F-49C8-B4CB-0C2D4043F51F/OfficeMac/"}
}
[io.file]::WriteAllbytes("$collarteralFolder\builds.txt",(Invoke-WebRequest -URI "$webUrlDownload/builds.txt").content) 

#compare temp build.txt with prod build.txt
#Initalise $origcontent array incase of first run
#if change detected then continue else stop
$origContent = @("")
if (test-path "$PublishFolder\builds.txt"){$origContent = Get-Content "$PublishFolder\builds.txt"}
$newContent = Get-Content "$collarteralFolder\builds.txt"
If ((compare-object $origContent $newContent).count -eq 0){
  Write-Verbose "No Change"
  Break
}

$MAUID_MAU3X="0409MSAU03"
$MAUID_WORD2016="0409MSWD15"
$MAUID_EXCEL2016="0409XCEL15"
$MAUID_POWERPOINT2016="0409PPT315"
$MAUID_OUTLOOK2016="0409OPIM15"
$MAUID_ONENOTE2016="0409ONMC15"
$MAUID_OFFICE2011="0409MSOF14"
$MAUID_LYNC2011="0409UCCP14"
$MAUID_SKYPE2016="0409MSFB16"


function BuildApplicationArray() {
  # Builds an array of all the MAU-enabled applications that we care about
  $MAUAPP=@()
  $MAUAPP+="$MAUID_MAU3X"
  $MAUAPP+="$MAUID_WORD2016"
  $MAUAPP+="$MAUID_EXCEL2016"
  $MAUAPP+="$MAUID_POWERPOINT2016"
  $MAUAPP+="$MAUID_OUTLOOK2016"
  $MAUAPP+="$MAUID_ONENOTE2016"
  $MAUAPP+="$MAUID_OFFICE2011"
  $MAUAPP+="$MAUID_LYNC2011"
  $MAUAPP+="$MAUID_SKYPE2016"
  return $MAUAPP
}
function DownloadUPdate ([Parameter(Mandatory=$true)]$Payload, [Parameter(Mandatory=$true)]$location)
{
        #Test-WritePath
        Write-Verbose "Starting $location - $collateral\$payload"
        
        #DOwnload to correct path

        #TEST BASELINE 
        $collateral = "$collarteralFolder"
          $wc = New-Object System.Net.WebClient
          $wc.DownloadFile($($location), "$collateral\$payload")
        
}



function DownloadCollateralFiles ([Parameter(Mandatory=$true)]$downloadarray,[Parameter(Mandatory=$true)]$weburldown){
  # Downloads XML/CAT collateral files
  foreach ($Down in $DownloadArray){
    $payload =""
    $locationstring = ""
    $UpdateVersions = ""
    Write-Verbose "$down"
    [io.file]::WriteAllbytes("$collarteralFolder\$down.xml",(Invoke-WebRequest -URI "$weburldown$down.xml").content) 
    [io.file]::WriteAllbytes("$collarteralFolder\$down.cat",(Invoke-WebRequest -URI "$weburldown$down.cat").content) 
    
   
    #get xml and find updateversion
    $log = "$collarteralFolder\$down.xml"
    $collateral = $collarteralFolder
    $patt = "<key>Update Version"
    $indx = Select-String $patt $log | ForEach-Object {$_.LineNumber}
    if ($indx.count -ge 2){
      $UpdateVersions= @((Get-Content $log)[$indx])
      $UpdateVersions=$UpdateVersions  -replace "</String>", ""
      $UpdateVersions=$UpdateVersions  -replace "<String>", ""
      $UpdateVersions=$UpdateVersions.trim()
      $pathtoput = "$($updateversions[0])"
      }
      elseif ($indx.count -eq 1){
              $UpdateVersions= @((Get-Content $log)[$indx])
      $UpdateVersions=$UpdateVersions  -replace "</String>", ""
      $UpdateVersions=$UpdateVersions  -replace "<String>", ""
      $UpdateVersions=$UpdateVersions.trim()
        $pathtoput="$($UpdateVersions)"
      }
      else {
        $pathtoput="Legacy"
      }
      
      
      
      #TEST COLLATERAL PATH EXISTS
      if (!(Test-Path "$collateral\$pathtoput")){
          new-item -ItemType Directory -Path $collateral -Name $pathtoput -Verbose
          }
      write-verbose "$collateral\$pathtoput\$down.xml"    
      Copy-Item -Path "$collarteralFolder\$down.xml"    -Destination "$collateral\$pathtoput\$down.xml" -Verbose
      Copy-Item -Path "$collarteralFolder\$down.cat"    -Destination "$collateral\$pathtoput\$down.cat" -Verbose
      
    
    #PAYLOAD NAME
    $log = "$collarteralFolder\$down.xml"
    $patt = "<KEY>Payload"
    $indxp = Select-String $patt $log | ForEach-Object {$_.LineNumber}
    write-verbose "$indx $($down)"
    $payload=@((Get-Content $log)[$indxp])
    $payload=$payload -replace "</String>", ""
    $payload=$payload -replace "<String>", ""
    $payload=$payload.trim()
    
    #DOWNLOAD FILE
    $patt = "<KEY>Location"
    $indx = Select-String $patt $log | ForEach-Object {$_.LineNumber}
    $locationstring= @((Get-Content $log)[$indx])
    $locationstring=$locationstring  -replace "</String>", ""
    $locationstring=$locationstring  -replace "<String>", ""
    $locationstring=$locationstring.trim()
    
    
     if ($indxp.count -le 1){
       write-verbose "One Detected $payload $locationstring"
      DownloadUPdate -Payload $payload -location $locationstring
      }
      else
      {
        for ($x = 0; $x -le ($($indxp.count)-1); $x += 1) 
        {
          write-verbose "One Detected $x"
          $pay = $($payload[$x])
          $loc = $($locationstring[$x])
          DownloadUPdate -Payload $pay -location $loc
        }


      }

    }
  }

$mauApp = BuildApplicationArray

DownloadCollateralFiles -downloadarray $mauApp -weburldown $webUrlDownload

#rename Folders
#Sainity check of folder before renaming
if ((Get-ChildItem $tempfolder).count -ge 10){

  Remove-Item $PublishFolder -recurse -Force
  start-sleep -Seconds 30
  Move-Item -Path $tempfolder -Destination "$publishBasePath"  

}