#CloudXNS-DDNS with PowerShell
#Github��Ŀ��ַ:https://github.com/lixuy/CloudXNS-DDNS-with-PowerShell
#������Ϣ: https://03k.org/cloudxns-ddns-with-powershell.html
$API_KEY="abcdefghijklmnopqrstuvwxyz1234567"
$SECRET_KEY="abcdefghijk12345"
#[����]�����Ϸ���д���CLoudXNS��API KEY��SECRET KEY.
$DDNS="home.xxxx.com"
#[����]�����Ϸ���д�������������myhome.xxx.com
#��ȷ�������������˺��ڴ��ڣ�����᷵��40x����
$UPTIME=59
#[��ѡ]�����µ�ʱ�������룩
#API������Ƶ�����ƣ����������ù��̼��
#�������Ҫѭ�������£������ֶ���Ӽƻ����񣩣���ע�ͻ���-1
$CHECKURL="http://ip.3322.org/"
#[��ѡ]���ڼ������ip�Ƿ���¹�����ַ������API����Ƶ��
#ע�ͻ���-1��������Ƿ��Ѿ����£�ֱ���ύip��������
#$LOGFILE="./ddns.log"
#[��ѡ]���ڼ�¼��־���ļ�·��*.log,ע�͵�����������־
#���ý���
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
Write-Host "����API����DNS�ɹ�`r"}
else {
Write-Host "����API����DNS����`r"
if ($Respond){Write-Host $Respond}
}}

if ($LOGFILE -match "\.log$"){
$null =stop-transcript;
Clear-Host
start-transcript -append -path $LOGFILE}
if (-not(
-join($API_KEY,$API_KEY.Length) -match "^[0-9a-z]{32}32$" -and`
-join($SECRET_KEY,$SECRET_KEY.Length) -match "^[0-9a-z]{16}16$"
)){Write-Warning "���API KEY���ÿ�����������������á�";read-host;exit}
do {
Write-Host "$(Get-date)`r"
if ($CHECKURL -match "^*://"){
$URLIP=new-object System.Net.WebClient
$URLIP.Encoding=[System.Text.Encoding]::UTF8
if($($URLIP.DownloadString($CHECKURL) -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"))
{$URLIP=$matches[0]}
else{$URLIP="�޷���ȡ���,��������,����ǽ��CHECKURL����`r"}
if($(([Net.DNS]::GetHostEntry($DDNS).AddressList|Where-Object -FilterScript {$_.AddressFamily -eq "InterNetwork"}).IPAddressToString|Out-String) -match "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")
{$PCIP=$matches[0]}
else{$PCIP="�޷���ȡ���,��������,����ǽ��DDNS����,������¼�ں�̨�Ƿ����`r"}
Write-Host "���ؽ������:$PCIP`r`n��ַ��ȡ���:$URLIP`r"
$SKIP=0
if ($URLIP -eq $PCIP){Write-Host "���һ�£���������`r";$SKIP=1}
}
$null =UPDNS;
if ($UPTIME -gt 0){Write-Host "�´μ�齫��$UPTIME<s>֮��`r";Start-Sleep $UPTIME};
}
while($UPTIME -gt 0)