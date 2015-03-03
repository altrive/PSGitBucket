Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#Default directory is %DEPLOYMENT_SOURCE% (D:\home\site\repository)

#this points to where the source files are, which is normally the root of the repo
$host.UI.WriteLine('$env:DEPLOYMENT_SOURCE: {0}' -f $env:DEPLOYMENT_SOURCE)

#the target of the deployment. Typically, this is the wwwroot folder
$host.UI.WriteLine('$env:DEPLOYMENT_TARGET: {0}' -f $env:DEPLOYMENT_TARGET)

#a temporary folder that can be used to store artifacts for the current build. This folder is deleted after the cmd is run.
$host.UI.WriteLine('$env:DEPLOYMENT_TEMP: {0}' -f $env:DEPLOYMENT_TEMP)

$host.UI.WriteLine('$env:deployment_branch: {0}' -f $env:deployment_branch)

$host.UI.WriteLine('$env:SCM_COMMIT_ID: {0}' -f $env:SCM_COMMIT_ID)

#WellKnownEnvironmentVariables
#https://github.com/projectkudu/kudu/blob/bb1e4bd69ccbd86268888aec88316f13f50b7108/Kudu.Core/Deployment/WellKnownEnvironmentVariables.cs

$env:GITBUCKET_HOME = "$env:HOME/GitBucket"
$env:CONTEXT_PATH = "/"

#Download GitBuckets
$source = 'https://github.com/takezoe/gitbucket/releases/download/2.8/gitbucket.war'
if(!(Test-Path "$env:WEBROOT_PATH\webapps"))
{
    New-Item "$env:WEBROOT_PATH\webapps" -ItemType Directory -ErrorAction Ignore > $null
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($source, "$env:WEBROOT_PATH\webapps\gitbucket.war")
    $wc.Dispose()
}

#Initialize Web.config
$xml = [xml]@'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="httpPlatformHandlerMain" modules="httpPlatformHandler" path="*" verb="*" resourceType="Unspecified" />
    </handlers>
    <httpPlatform processPath="{{PROCESS_PATH}}" arguments="{{ARGUMENTS}}">
      <environmentVariables>
      </environmentVariables>
    </httpPlatform>
  </system.webServer>
</configuration>
'@
$xml.configuration."system.webServer".httpPlatform.processPath = "$env:JAVA_HOME\bin\java.exe"
$xml.configuration."system.webServer".httpPlatform.arguments   = [Environment]::ExpandEnvironmentVariables("$env:AZURE_JETTY9_CMDLINE")

$xmlText = [System.Xml.Linq.XElement]::Parse($xml.OuterXml).ToString()
Set-Content -Path "$env:WEBROOT_PATH\Web.config" -Value $xmlText -Encoding UTF8
