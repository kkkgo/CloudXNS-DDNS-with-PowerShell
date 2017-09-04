#CloudXNS-DDNS with PowerShell
#Github项目地址:https://github.com/lixuy/CloudXNS-DDNS-with-PowerShell
#更多信息: https://03k.org/cloudxns-ddns-with-powershell.html
$API_KEY="abcdefghijklmnopqrstuvwxyz1234567"
$SECRET_KEY="abcdefghijk12345"
#[必填]请在上方填写你的CLoudXNS的API KEY和SECRET KEY.
$DDNS="home.xxxx.com"
#[必填]请在上方填写你的域名，比如myhome.xxx.com
#请确保所填域名在账号内存在，否则会返回40x错误
$CARD="AA-BB-CC-00-11-22"
#[必填]指定网卡的mac地址
$UPTIME=59
#[可选]检查更新的时间间隔（秒）
#API调用有频率限制，不建议设置过短间隔
#如果不需要循环检查更新（比如手动添加计划任务），请注释或填-1
#$LOGFILE="./ddns.log"
#[可选]用于记录日志的文件路径*.log,注释掉将不保存日志
#配置结束
$URL="http://www.cloudxns.net/api2/ddns"


Function UPDNS() 
{if ($SKIP) {return -1;}
$JSON = @"
  {"domain":"$DDNS","ip":"$CARDIP"}
"@
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
Write-Host "调用API更新DNS成功`r"}
else {
Write-Host "调用API更新DNS出错`r"
if ($Respond){Write-Host $Respond}
}}

if ($LOGFILE -match "\.log$"){
$null =stop-transcript;
Clear-Host
start-transcript -append -path $LOGFILE}
if (-not(
-join($API_KEY,$API_KEY.Length) -match "^[0-9a-z]{32}32$" -and`
-join($SECRET_KEY,$SECRET_KEY.Length) -match "^[0-9a-z]{16}16$"
)){Write-Warning "你的API KEY配置可能有误，请检查你的配置。";read-host;exit}
do {
Write-Host "$(Get-date)`r"
if($((Get-NetIPAddress -ifIndex $(Get-NetAdapter | Where-Object -Property MacAddress -EQ $CARD).ifIndex -SuffixOrigin Dhcp -AddressFamily IPv4).IPAddress) -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")
{$CARDIP=$matches[0]}
else{$CARDIP="无法获取网卡IP,请检查网络和MAC地址`r"}
if($(([Net.DNS]::GetHostEntry($DDNS).AddressList|Where-Object -FilterScript {$_.AddressFamily -eq "InterNetwork"}).IPAddressToString|Out-String) -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")
{$PCIP=$matches[0]}
else{$PCIP="无法获取结果,请检查网络,防火墙和DDNS参数,域名记录在后台是否存在`r"}
Write-Host "本地解析结果:$PCIP`r`n网卡获取结果:$CARDIP`r"
$SKIP=0
if ($CARDIP -eq $PCIP){Write-Host "结果一致，跳过更新`r";$SKIP=1}
$null =UPDNS;
if ($UPTIME -gt 0){Write-Host "下次检查将在$UPTIME<s>之后`r";Start-Sleep $UPTIME};
}
while($UPTIME -gt 0)