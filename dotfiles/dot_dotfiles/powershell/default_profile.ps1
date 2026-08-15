if(!$env:DEFAULT_PROFILE_LOADED )
{
	$env:DEFAULT_PROFILE_LOADED = $True

	$start = Get-Date

	# Check for file existence. If CMDer exists, let's try to load that:
	if ((Test-Path "c:\tools\cmdermini\") -and (Test-Path "c:\tools\cmdermini\vendor\profile.ps1")) {
		if (-Not (Test-Path Env:\CMDER_ROOT)) {
			$env:CMDER_ROOT="C:\tools\cmdermini\"
			$env:ConEmuDir="C:\tools\cmdermini\vendor\conemu-maximus5"
		}
		. "c:\tools\cmdermini\vendor\profile.ps1"
	} else {
			# There is no CMDer, so just load our profile directly:
			$target = (Get-Item $PSCommandPath).Target
			if ($target -eq $null) {
				. "$PSScriptRoot\user_profile.ps1"
			} else {
				# If the current script is symlinked, use the target:
				$real_root_dir = Split-Path $target
				. "$real_root_dir\user_profile.ps1"
			}
	}

	# Chocolatey profile
	$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
	if (Test-Path($ChocolateyProfile)) {
		Import-Module "$ChocolateyProfile"
	}

	$end = Get-Date
	Write-Host "Loading default_profile.ps1 $(($end - $start).TotalMilliseconds)ms." -Fore DarkGray
}
else
{
	Write-Host "Blocked double-load of `default_profile.ps1`." -Fore DarkGray
}