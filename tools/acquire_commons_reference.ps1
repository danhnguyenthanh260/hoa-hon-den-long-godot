param(
    [Parameter(Mandatory = $true)]
    [string]$TitlesFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [ValidateRange(1024, 4096)]
    [int]$MaxWidth = 2560,

    [switch]$Originals
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Strip-Html([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    $plain = [regex]::Replace($Value, '<[^>]+>', '')
    return [System.Net.WebUtility]::HtmlDecode($plain).Trim()
}

function Metadata-Value($Metadata, [string]$Name) {
    if ($null -eq $Metadata) {
        return ''
    }

    $property = $Metadata.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return ''
    }

    return Strip-Html ([string]$property.Value.value)
}

$titlesPath = (Resolve-Path -LiteralPath $TitlesFile).Path
$titles = Get-Content -LiteralPath $titlesPath -Encoding UTF8 |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith('#') }

if ($titles.Count -eq 0) {
    throw "No Commons file titles found in $titlesPath"
}

if ($titles.Count -gt 50) {
    throw 'A single acquisition batch is limited to 50 reviewed files.'
}

$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
$sourcePath = Join-Path $outputPath 'source'
[System.IO.Directory]::CreateDirectory($sourcePath) | Out-Null
$manifestPath = Join-Path $outputPath 'manifest.json'
$previousByTitle = @{}
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    $previousManifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($previousEntry in @($previousManifest.files)) {
        $previousByTitle[[string]$previousEntry.commons_title] = $previousEntry
    }
}

$joinedTitles = [uri]::EscapeDataString(($titles -join '|'))
$apiUrl = 'https://commons.wikimedia.org/w/api.php' +
    '?action=query&format=json&prop=info%7Cimageinfo&inprop=url' +
    '&iiprop=url%7Cextmetadata%7Csize%7Csha1%7Cmime%7Ctimestamp&iiurlwidth=' + $MaxWidth +
    '&titles=' + $joinedTitles
$headers = @{
    'User-Agent' = 'hoa-hon-den-long-reference-acquisition/1.0'
}

$apiResponse = Invoke-WebRequest -Uri $apiUrl -Headers $headers -UseBasicParsing -TimeoutSec 60
$apiJson = [System.Text.Encoding]::UTF8.GetString($apiResponse.RawContentStream.ToArray())
$response = $apiJson | ConvertFrom-Json
$pages = @($response.query.pages.PSObject.Properties.Value)
$entries = @()

for ($index = 0; $index -lt $titles.Count; $index++) {
    $requestedTitle = $titles[$index]
    $page = $pages | Where-Object { $_.title -eq $requestedTitle } | Select-Object -First 1
    if ($null -eq $page -or $page.missing) {
        throw "Commons file not found: $requestedTitle"
    }

    $imageInfo = $page.imageinfo[0]
    $metadata = $imageInfo.extmetadata
    $license = Metadata-Value $metadata 'LicenseShortName'
    $licenseUrl = Metadata-Value $metadata 'LicenseUrl'

    if ($license -notmatch '^(CC0|Public domain|CC BY( |$))') {
        throw "Rejected license '$license' for $requestedTitle. This batch accepts CC0, public domain, or CC BY only."
    }

    $downloadUrl = if ($Originals -or -not $imageInfo.thumburl) { $imageInfo.url } else { $imageInfo.thumburl }
    $downloadedMaxWidth = if ($downloadUrl -eq $imageInfo.url) { $null } else { $MaxWidth }
    $extension = [System.IO.Path]::GetExtension(([uri]$imageInfo.url).AbsolutePath).ToLowerInvariant()
    if ($extension -notin @('.jpg', '.jpeg', '.png', '.tif', '.tiff')) {
        throw "Unsupported image extension '$extension' for $requestedTitle"
    }

    $fileName = '{0:d2}{1}' -f ($index + 1), $extension
    $destination = Join-Path $sourcePath $fileName
    $existing = Get-Item -LiteralPath $destination -ErrorAction SilentlyContinue
    $previous = $previousByTitle[$requestedTitle]
    $existingSha256 = if ($null -ne $existing) {
        (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    } else {
        ''
    }
    $sameRecordedRevision = $null -ne $previous -and (
        [string]::IsNullOrWhiteSpace([string]$previous.remote_sha1) -or
        [string]$previous.remote_sha1 -eq [string]$imageInfo.sha1
    )
    $existingIsOriginal = $downloadUrl -eq $imageInfo.url -and
        $null -ne $existing -and
        $existing.Length -eq [int64]$imageInfo.size -and
        $null -ne $previous -and
        $existingSha256 -eq ([string]$previous.sha256).ToLowerInvariant() -and
        [string]$previous.original_url -eq [string]$imageInfo.url -and
        $sameRecordedRevision

    if ($existingIsOriginal) {
        Write-Output "Reused $fileName <- $requestedTitle"
        $downloadExit = 0
    }
    else {
        & curl.exe --location --fail --silent --show-error `
            --retry 4 --retry-all-errors --retry-delay 10 `
            --user-agent $headers['User-Agent'] `
            --output $destination $downloadUrl
        $downloadExit = $LASTEXITCODE
    }

    if ($downloadExit -ne 0) {
        # Wikimedia can reject an on-demand thumbnail while the immutable
        # original remains available. Falling back preserves evidence quality
        # and avoids treating a failed thumbnail transform as a missing source.
        if ($downloadUrl -eq $imageInfo.url) {
            throw "Download failed for $requestedTitle with curl exit code $downloadExit"
        }

        Write-Warning "Thumbnail unavailable for $requestedTitle; downloading the original."
        $downloadUrl = $imageInfo.url
        $downloadedMaxWidth = $null
        & curl.exe --location --fail --silent --show-error `
            --retry 4 --retry-all-errors --retry-delay 10 `
            --user-agent $headers['User-Agent'] `
            --output $destination $downloadUrl
        if ($LASTEXITCODE -ne 0) {
            throw "Original download failed for $requestedTitle with curl exit code $LASTEXITCODE"
        }
    }
    $hash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()

    $entries += [ordered]@{
        id = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        local_path = ('source/' + $fileName)
        # Keep the reviewed UTF-8 title from the input file. Windows PowerShell
        # can misdecode MediaWiki's response title when the HTTP charset is
        # omitted, while the canonical URL and binary remain correct.
        commons_title = $requestedTitle
        page_id = $page.pageid
        page_revision_id = $page.lastrevid
        commons_page = $page.fullurl
        original_url = $imageInfo.url
        remote_sha1 = $imageInfo.sha1
        image_timestamp = $imageInfo.timestamp
        mime = $imageInfo.mime
        downloaded_url = $downloadUrl
        original_width = $imageInfo.width
        original_height = $imageInfo.height
        downloaded_max_width = $downloadedMaxWidth
        author = Metadata-Value $metadata 'Artist'
        credit = Metadata-Value $metadata 'Credit'
        license = $license
        license_url = $licenseUrl
        attribution_required = ($license -match '^CC BY')
        commercial_use = ($license -match '^(CC0|Public domain|CC BY)')
        derivatives_allowed = ($license -match '^(CC0|Public domain|CC BY)')
        copyright_redistribution_allowed = ($license -match '^(CC0|Public domain|CC BY)')
        acquisition_date = (Get-Date).ToString('yyyy-MM-dd')
        sha256 = $hash
        coverage = @()
        review_status = 'unclassified'
        identifiable_people = $null
        personality_rights_review = 'unreviewed'
        public_redistribution_decision = 'pending'
        use_scope = 'reference_only'
        used_by_assets = @()
    }

    if (-not $existingIsOriginal) {
        Write-Output "Downloaded $fileName <- $requestedTitle"
        Start-Sleep -Seconds 8
    }
}

$coveragePath = Join-Path $outputPath 'coverage.json'
if (Test-Path -LiteralPath $coveragePath -PathType Leaf) {
    $coverageMap = Get-Content -LiteralPath $coveragePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $defaults = $coverageMap.PSObject.Properties['_defaults']
    foreach ($entry in $entries) {
        if ($null -ne $defaults) {
            foreach ($property in $defaults.Value.PSObject.Properties) {
                $entry[$property.Name] = $property.Value
            }
        }
        $classification = $coverageMap.PSObject.Properties[[string]$entry.id]
        if ($null -ne $classification) {
            foreach ($property in $classification.Value.PSObject.Properties) {
                $entry[$property.Name] = $property.Value
            }
        }
    }
}

$manifest = [ordered]@{
    schema_version = 1
    source = 'Wikimedia Commons'
    source_policy = 'Each file was reviewed individually; Commons is not treated as a blanket license.'
    asset_readiness = 'reference_only_incomplete'
    max_download_width = if ($Originals) { $null } else { $MaxWidth }
    generated_at = (Get-Date).ToString('o')
    files = $entries
}

$manifestJson = $manifest | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText(
    $manifestPath,
    $manifestJson,
    [System.Text.UTF8Encoding]::new($false)
)

$attributionLines = [System.Collections.Generic.List[string]]::new()
$attributionLines.Add('# Attribution')
$attributionLines.Add('')
$attributionLines.Add('Source images were renamed locally but otherwise downloaded at the resolution recorded in `manifest.json`.')
$attributionLines.Add('')
foreach ($entry in $entries) {
    $title = ([string]$entry.commons_title).Replace('|', '\|')
    $author = ([string]$entry.author).Replace('|', '\|')
    $line = '- `{0}` [{1}]({2}) - {3} - [{4}]({5})' -f @(
        $entry.id,
        $title,
        $entry.commons_page,
        $author,
        $entry.license,
        $entry.license_url
    )
    $attributionLines.Add($line)
}
$attributionPath = Join-Path $outputPath 'ATTRIBUTION.md'
[System.IO.File]::WriteAllText(
    $attributionPath,
    ($attributionLines -join [Environment]::NewLine),
    [System.Text.UTF8Encoding]::new($false)
)

Write-Output "Manifest: $manifestPath"
Write-Output "Attribution: $attributionPath"
