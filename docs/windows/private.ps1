# private.ps1: tightens Windows privacy in the DJ VM, on top of Win11Debloat.
# Run in PowerShell as admin:  powershell -ExecutionPolicy Bypass -File Z:\private.ps1
# Everything here is a registry setting, a service or a scheduled task, so it can
# all be switched back by hand. Restart Windows afterwards.
#Requires -RunAsAdministrator

function Set-Reg($path, $name, $value) {
  if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
  Set-ItemProperty -Path $path -Name $name -Value $value -Type DWord
}

# Diagnostic data as low as the edition allows, no feedback pop-ups, and no
# tailored tips built from it
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DisableOneSettingsDownloads' 1
Set-Reg 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent' 'DisableTailoredExperiencesWithDiagnosticData' 1
Set-Reg 'HKCU:\Software\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0

# The services and tasks that collect and send it
foreach ($s in 'DiagTrack', 'dmwappushservice') {
  Stop-Service $s -Force -ErrorAction SilentlyContinue
  Set-Service $s -StartupType Disabled -ErrorAction SilentlyContinue
}
foreach ($t in '\Microsoft\Windows\Customer Experience Improvement Program\',
               '\Microsoft\Windows\Application Experience\',
               '\Microsoft\Windows\Feedback\Siuf\',
               '\Microsoft\Windows\Windows Error Reporting\') {
  Get-ScheduledTask -TaskPath $t -ErrorAction SilentlyContinue | Disable-ScheduledTask | Out-Null
}
Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' 'Disabled' 1

# No advertising ID, activity history, or clipboard synced to other devices
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' 'DisabledByGroupPolicy' 1
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0
Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowCrossDeviceClipboard' 0

# Typing, inking and speech stay on the machine
Set-Reg 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
Set-Reg 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
Set-Reg 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 0
Set-Reg 'HKCU:\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 0
Set-Reg 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 0

# Start doesn't keep track of which apps you open
Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0

# Apps can't read things this VM has no business with. The microphone stays
# allowed for Audacity.
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore'
foreach ($c in 'webcam', 'contacts', 'appointments', 'phoneCall', 'phoneCallHistory', 'chat', 'email',
               'userAccountInformation', 'userDataTasks', 'userNotificationListener', 'radios',
               'bluetoothSync', 'appDiagnostics', 'documentsLibrary', 'picturesLibrary', 'videosLibrary') {
  if (-not (Test-Path "$store\$c")) { New-Item -Path "$store\$c" -Force | Out-Null }
  Set-ItemProperty -Path "$store\$c" -Name 'Value' -Value 'Deny' -Type String
}

Write-Host 'Done. Restart Windows so everything takes.'
