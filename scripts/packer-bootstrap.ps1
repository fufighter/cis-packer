<powershell>
Function InstallWinRM {
  # Configure winRM over HTTPs for packer communications

  # First, make sure WinRM can't be connected to
  netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=block

  # Delete any existing WinRM listeners
  winrm delete winrm/config/listener?Address=*+Transport=HTTP  2>$Null
  winrm delete winrm/config/listener?Address=*+Transport=HTTPS 2>$Null

  # Disable group policies which block basic authentication and unencrypted login
  Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client -Name AllowBasic -Value 1
  Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client -Name AllowUnencryptedTraffic -Value 1
  Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service -Name AllowBasic -Value 1
  Set-ItemProperty -Path HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service -Name AllowUnencryptedTraffic -Value 1

  #Create self signed certificate for packer
  $Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
  New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

  #General winRM config
  winrm quickconfig -q
  winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
  winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
  winrm set "winrm/config/service/auth" '@{Basic="true"}'
  winrm set "winrm/config/client/auth" '@{Basic="true"}'
  winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
  winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"packer`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"

  # Configure UAC to allow privilege elevation in remote shells
  $Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
  $Setting = 'LocalAccountTokenFilterPolicy'
  Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

  # Configure and restart the WinRM Service; Enable the required firewall exception
  Stop-Service -Name WinRM
  Set-Service -Name WinRM -StartupType Automatic
  netsh advfirewall firewall add rule name="Open Port 5986" dir=in action=allow protocol=TCP localport=5986
  Start-Service -Name WinRM
}

Start-Transcript c:/packer-userdata.log
InstallWinRM
</powershell>
