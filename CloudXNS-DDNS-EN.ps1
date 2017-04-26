#CloudXNS-DDNS with PowerShell
#Github: https://github.com/lixuy/CloudXNS-DDNS-with-PowerShell
#More: https://03k.org/cloudxns-ddns-with-powershell.html
$API_KEY="abcdefghijklmnopqrstuvwxyz1234567"
$SECRET_KEY="abcdefghijk12345"
#[Required]Please fill in your API KEY and SECRET KEY.
$DDNS="home.xxxx.com"
#[Required]Please fill in your domain name, such as home.xxxx.com.
#Please make sure that the filled domain name exists in your account.
$UPTIME=59
#[Optional]Updated time interval (seconds)
#API has a frequency limit, it is not recommended to set too short a time interval.
#If you do not need to check for updates (such as manually adding scheduled tasks),
#please comment this line of code
$CHECKURI="http://myip.ipip.net/"
#[Optional]Used to obtain the public network ip address, reduce the API call frequency.
#Comment this line of code will submit the ip update request directly.
#Supports URIs that begin with http:, https:, ftp :, and file: identifiers.
#$LOGFILE="./ddns.log"
#[Optional]The file path used to record the log * .log, 
#commented this line of code will not save the log.
#The configuration ends
$URL="http://www.cloudxns.net/api2/ddns"
$JSON = @"
  {"domain":"$DDNS"}
"@

Function UPDNS() 
{if ($SKIP) {return -1;}
$DATE=get-Date -format r
$md5=New-Object System.Text.StringBuilder 
[System.Security.Cryptography.HashAlgorithm]::Create("MD5").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($API_KEY+$URL+$JSON+$DATE+$SECRET_KEY))|%{[Void]$md5.Append($_.ToString("x2"))}
$HMAC =$md5.ToString()
$POST=new-object System.Net.WebClient
$POST.Encoding=[System.Text.Encoding]::UTF8
$POST.Headers.Add("API-KEY",$API_KEY)
$POST.Headers.Add("API-REQUEST-DATE",$DATE)
$POST.Headers.Add("API-HMAC",$HMAC)
$POST.Headers.Add("HttpRequestHeader.Accept", "json");
$POST.Headers.Add("HttpRequestHeader.ContentType","application/x-www-form-urlencoded; charset=UTF-8");
$Respond=$POST.UploadString($URL,"POST", $JSON);
if ($Respond -match "success"){
Write-Host "Call API update DNS successfully`r"}
else {
Write-Host "Call API update DNS error`r"
if ($Respond){Write-Host $Respond}
}
}

if ($LOGFILE -match "\.log$"){
$null =stop-transcript;
Clear-Host
start-transcript -append -path $LOGFILE}
if (-not(
-join($API_KEY,$API_KEY.Length) -match "^[0-9a-z]{32}32$" -and`
-join($SECRET_KEY,$SECRET_KEY.Length) -match "^[0-9a-z]{16}16$"
)){Write-Warning "Your API KEY configuration may be incorrect, please check your configuration.";read-host;exit}
Write-Host "CloudXNS-DDNS with PowerShell"
do {
Write-Host "$(Get-date)`r"
if ($CHECKURI -match "^*://"){
$URLIP=new-object System.Net.WebClient
$URLIP.Encoding=[System.Text.Encoding]::UTF8
if($($URLIP.DownloadString($CHECKURI) -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"))
{$URLIP=$matches[0]}
else{$URLIP="Can not get results, check the network, firewall, and CHECKURI parameters`r"}
if($(([Net.DNS]::GetHostEntry($DDNS).AddressList|Where-Object -FilterScript {$_.AddressFamily -eq "InterNetwork"}).IPAddressToString|Out-String) -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")
{$PCIP=$matches[0]}
else{$PCIP="Can not get the results, please check the network, firewall and DDNS parameters, domain name records in the background`r"}
Write-Host "Local resolution results:$PCIP`r`nThe result from the URL:$URLIP`r"
$SKIP=0
if ($URLIP -eq $PCIP){Write-Host "The results are consistent, skip the update`r";$SKIP=1}
}
$null =UPDNS;
if ($UPTIME -gt 0){Write-Host "The next check will be after $UPTIME<s>`r";Start-Sleep $UPTIME};
}
while($UPTIME -gt 0)
