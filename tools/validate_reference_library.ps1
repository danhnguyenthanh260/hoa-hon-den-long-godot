param(
    [string]$Root = '.\reference-library',
    [switch]$RequireReviewed,
    [switch]$RequirePublicRedistribution,
    [switch]$RequireHeroReady
)

$ErrorActionPreference = 'Stop'
$acceptedLicenses = @('CC0', 'Public domain', 'CC BY 1.0', 'CC BY 2.0', 'CC BY 2.5', 'CC BY 3.0', 'CC BY 4.0')
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$checkedFiles = 0

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$manifests = @(Get-ChildItem -LiteralPath $rootPath -Filter manifest.json -File -Recurse)
if ($manifests.Count -eq 0) {
    throw "No manifest.json files found below $rootPath"
}

foreach ($manifestFile in $manifests) {
    try {
        $manifest = Get-Content -LiteralPath $manifestFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        $errors.Add("$($manifestFile.FullName): invalid JSON: $($_.Exception.Message)")
        continue
    }

    if ([int]$manifest.schema_version -ne 1) {
        $errors.Add("$($manifestFile.FullName): unsupported schema_version '$($manifest.schema_version)'")
    }
    if ($RequireHeroReady -and [string]$manifest.asset_readiness -ne 'hero_ready') {
        $errors.Add("$($manifestFile.FullName): asset_readiness is '$($manifest.asset_readiness)', not hero_ready")
    }

    $manifestIds = @($manifest.files | ForEach-Object { [string]$_.id })
    $manifestPaths = @($manifest.files | ForEach-Object { [string]$_.local_path })
    $sourceFiles = @(Get-ChildItem -LiteralPath (Join-Path $manifestFile.Directory.FullName 'source') -File |
        ForEach-Object { 'source/' + $_.Name })
    foreach ($orphan in @($sourceFiles | Where-Object { $manifestPaths -notcontains $_ })) {
        $errors.Add("$($manifestFile.Directory.Name): orphan source file '$orphan'")
    }
    foreach ($missingSource in @($manifestPaths | Where-Object { $sourceFiles -notcontains $_ })) {
        $errors.Add("$($manifestFile.Directory.Name): manifest path absent from source folder '$missingSource'")
    }

    $titlesPath = Join-Path $manifestFile.Directory.FullName 'titles.txt'
    if (Test-Path -LiteralPath $titlesPath -PathType Leaf) {
        $titles = @(Get-Content -LiteralPath $titlesPath -Encoding UTF8 |
            ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
        $manifestTitles = @($manifest.files | ForEach-Object { [string]$_.commons_title })
        if ($titles.Count -ne $manifestTitles.Count -or @($titles | Where-Object { $manifestTitles -notcontains $_ }).Count -gt 0) {
            $errors.Add("$($manifestFile.Directory.Name): titles.txt and manifest are not a bijection")
        }
    }

    $coveragePath = Join-Path $manifestFile.Directory.FullName 'coverage.json'
    if (Test-Path -LiteralPath $coveragePath -PathType Leaf) {
        $coverageMap = Get-Content -LiteralPath $coveragePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $coverageIds = @($coverageMap.PSObject.Properties.Name | Where-Object { $_ -ne '_defaults' })
        if ($coverageIds.Count -ne $manifestIds.Count -or @($coverageIds | Where-Object { $manifestIds -notcontains $_ }).Count -gt 0) {
            $errors.Add("$($manifestFile.Directory.Name): coverage.json and manifest IDs are not a bijection")
        }
    }

    $attributionPath = Join-Path $manifestFile.Directory.FullName 'ATTRIBUTION.md'
    $attributionText = if (Test-Path -LiteralPath $attributionPath -PathType Leaf) {
        Get-Content -LiteralPath $attributionPath -Raw -Encoding UTF8
    } else { '' }

    foreach ($entry in @($manifest.files)) {
        $checkedFiles += 1
        $prefix = "$($manifestFile.Directory.Name)/$($entry.id)"
        foreach ($required in @('id', 'local_path', 'commons_page', 'original_url', 'author', 'license', 'license_url', 'sha256', 'review_status', 'page_id', 'page_revision_id', 'remote_sha1', 'image_timestamp', 'mime', 'personality_rights_review', 'public_redistribution_decision', 'use_scope')) {
            if ([string]::IsNullOrWhiteSpace([string]$entry.$required)) {
                $errors.Add("${prefix}: missing $required")
            }
        }
        if ($RequireReviewed) {
            foreach ($classification in @('coverage_role', 'camera_facing')) {
                if ([string]::IsNullOrWhiteSpace([string]$entry.$classification)) {
                    $errors.Add("${prefix}: missing reviewed classification '$classification'")
                }
            }
            if (@($entry.coverage).Count -eq 0) {
                $errors.Add("${prefix}: missing reviewed coverage tags")
            }
        }

        if ($acceptedLicenses -notcontains [string]$entry.license) {
            $errors.Add("${prefix}: license '$($entry.license)' is not accepted by the automated gate")
        }

        $assetPath = Join-Path $manifestFile.Directory.FullName ([string]$entry.local_path)
        if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
            $errors.Add("${prefix}: missing local file '$($entry.local_path)'")
            continue
        }

        $actualHash = (Get-FileHash -LiteralPath $assetPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne ([string]$entry.sha256).ToLowerInvariant()) {
            $errors.Add("${prefix}: SHA-256 mismatch")
        }

        foreach ($right in @('commercial_use', 'derivatives_allowed', 'copyright_redistribution_allowed')) {
            if ($entry.$right -ne $true) {
                $errors.Add("${prefix}: $right is not explicitly true")
            }
        }
        if ($RequirePublicRedistribution -and [string]$entry.public_redistribution_decision -ne 'approved') {
            $errors.Add("${prefix}: public redistribution is '$($entry.public_redistribution_decision)', not approved")
        }
        elseif ([string]$entry.public_redistribution_decision -ne 'approved') {
            $warnings.Add("${prefix}: public redistribution remains '$($entry.public_redistribution_decision)'")
        }
        if ($attributionText -notmatch [regex]::Escape("``$($entry.id)``")) {
            $errors.Add("${prefix}: missing attribution entry")
        }

        $reviewStatus = [string]$entry.review_status
        if ($reviewStatus -notin @('reviewed', 'reviewed_limited')) {
            $message = "${prefix}: visual review status '$reviewStatus' is not accepted"
            if ($RequireReviewed) {
                $errors.Add($message)
            }
            else {
                $warnings.Add($message)
            }
        }
    }
}

foreach ($warning in $warnings) {
    Write-Warning $warning
}
foreach ($errorMessage in $errors) {
    Write-Output "ERROR: $errorMessage"
}

if ($errors.Count -gt 0) {
    Write-Output "REFERENCE LIBRARY FAILED: $($errors.Count) error(s), $($warnings.Count) warning(s), $checkedFiles file(s) checked"
    exit 1
}

Write-Output "REFERENCE LIBRARY OK: $checkedFiles file(s), $($manifests.Count) manifest(s), $($warnings.Count) warning(s)"
