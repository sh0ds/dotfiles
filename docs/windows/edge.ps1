# edge.ps1: sets up Edge in the DJ VM as a quiet, private browser through policies.
# Run in PowerShell as admin:  powershell -ExecutionPolicy Bypass -File Z:\edge.ps1
# Edge says "managed by your organization" afterwards, that's these policies.
# Check them at edge://policy, remove them all with:
#   Remove-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Recurse
#Requires -RunAsAdministrator

$edge = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
New-Item -Path $edge -Force | Out-Null
function Set-Policy($name, $value) {
  Set-ItemProperty -Path $edge -Name $name -Value $value -Type DWord
}

# Straight to an empty browser: no welcome tour, no Microsoft account, no sync
Set-Policy 'HideFirstRunExperience' 1
Set-Policy 'BrowserSignin' 0
Set-Policy 'ImplicitSignInEnabled' 0
Set-Policy 'SyncDisabled' 1

# Tracking: strict prevention, no third-party cookies, nothing sent to Microsoft
Set-Policy 'TrackingPrevention' 3
Set-Policy 'BlockThirdPartyCookies' 1
Set-Policy 'ConfigureDoNotTrack' 1
Set-Policy 'PersonalizationReportingEnabled' 0
Set-Policy 'UserFeedbackAllowed' 0
Set-Policy 'SearchSuggestEnabled' 0
Set-Policy 'LocalProvidersEnabled' 0
Set-Policy 'AlternateErrorPagesEnabled' 0
Set-Policy 'ResolveNavigationErrorsUseWebService' 0
Set-Policy 'NetworkPredictionOptions' 2

# A plain new tab page: no news, no background, no suggested sites
Set-Policy 'NewTabPageContentEnabled' 0
Set-Policy 'NewTabPageQuickLinksEnabled' 0
Set-Policy 'NewTabPageHideDefaultTopSites' 1
Set-Policy 'NewTabPageAllowedBackgroundTypes' 3

# No Copilot, sidebar or AI extras
Set-Policy 'HubsSidebarEnabled' 0
Set-Policy 'CopilotPageContext' 0
Set-Policy 'DiscoverPageContextEnabled' 0
Set-Policy 'Microsoft365CopilotChatIconEnabled' 0
Set-Policy 'ComposeInlineEnabled' 0
Set-Policy 'GenAILocalFoundationalModelSettings' 1

# No shopping, rewards, promotions or other clutter
Set-Policy 'EdgeShoppingAssistantEnabled' 0
Set-Policy 'EdgeWalletCheckoutEnabled' 0
Set-Policy 'ShowMicrosoftRewards' 0
Set-Policy 'ShowRecommendationsEnabled' 0
Set-Policy 'SpotlightExperiencesAndRecommendationsEnabled' 0
Set-Policy 'MicrosoftEdgeInsiderPromotionEnabled' 0
Set-Policy 'ShowAcrobatSubscriptionButton' 0
Set-Policy 'ShowPDFDefaultRecommendationsEnabled' 0
Set-Policy 'EdgeCollectionsEnabled' 0
Set-Policy 'EdgeFollowEnabled' 0
Set-Policy 'EdgeEDropEnabled' 0

# Passwords live in Proton Pass, not here
Set-Policy 'PasswordManagerEnabled' 0

# Nothing running once the window is closed, it's a VM with CPU to spare for rekordbox
Set-Policy 'StartupBoostEnabled' 0
Set-Policy 'BackgroundModeEnabled' 0

Write-Host 'Done. Close Edge completely and open it again.'
