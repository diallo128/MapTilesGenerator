<#
.SYNOPSIS
    Generates map tiles from a source image into z/x/y folder structure.

.DESCRIPTION
    This script scales an input image into multiple zoom levels and cuts it into square tiles.
    The resulting tiles are stored in a standard z/x/y layout. Output can be in PNG (default),
    WebP-lossless, or AVIF-lossless formats. It is designed for reproducible, lossless outputs
    with ASCII-only console feedback and minimal dependencies.

.AUTHOR
    Diallo128

.VERSION
    1.2.0

.DATE
    2025-10-24

.LICENSE
    MIT License

.REQUIRES
    PowerShell 5.1 or later
    ImageMagick ('magick' command) in PATH

.CHANGELOG
    1.2.0 - Added output format selection (png/webp/avif), inline documentation and metadata header
    1.1.0 - Improved error handling, progress spinner and directory structure logic
    1.0.0 - Initial version
#>

#requires -Version 5.1

function New-MapTiles {
<#
.SYNOPSIS
Generate tiled map images (z/x/y layout) from a source raster.

.DESCRIPTION
Scales an input image into multiple zoom levels and crops it into square tiles
of a fixed size (TileSize). Output is written into a z/x/y.<ext> folder layout.
The default output format is PNG (lossless). Optionally, WebP-lossless and
AVIF-lossless can be used. Output and logging use ASCII-only characters.

.PARAMETER Source
Path to an existing source image file.

.PARAMETER Target
Base output folder for the tile hierarchy. Unless -NoTimestamp is specified,
a timestamp is appended to the folder name to avoid overwriting existing data.

.PARAMETER MaxZoom
Maximum zoom level (0 = only a single tile). Default: 6. Allowed: 0..12.

.PARAMETER TileSize
Tile edge length in pixels. Default: 256.

.PARAMETER NoTimestamp
If set, no timestamp is appended. The specified target folder is used as-is.
Existing same-named files are overwritten; unrelated files remain untouched.

.PARAMETER Format
Output format for tiles. Allowed: png, webp, avif. Default: png.
All formats are configured for lossless encoding.

.EXAMPLE
New-MapTiles -Source "C:\data\map.png" -Target "C:\tiles"

Generates PNG tiles, zoom levels 0..6, tile size 256, target folder with timestamp.

.EXAMPLE
New-MapTiles -Source ".\big.tif" -Target ".\tiles" -NoTimestamp -MaxZoom 8 -TileSize 512

Generates PNG tiles without timestamp, up to zoom 8, tile size 512.

.EXAMPLE
New-MapTiles -Source "map.jpg" -Target "tiles" -Format webp

Generates WebP-lossless tiles.

.EXAMPLE
New-MapTiles -Source "map.exr" -Target "tiles_avif" -Format avif -NoTimestamp

Generates AVIF-lossless tiles without timestamp.
#>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        # Path to the source image file
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-Path $_ -PathType Leaf)) { throw "Source file not found: $_" }
            $true
        })]
        [string]$Source,

        # Target output directory (base folder for all tiles)
        [Parameter(Mandatory = $true)]
        [string]$Target,

        # Maximum zoom level (number of zoom levels generated = MaxZoom + 1)
        [ValidateRange(0,12)]
        [int]$MaxZoom = 6,

        # Pixel size of a single tile (e.g., 256x256)
        [int]$TileSize = 256,

        # If specified, prevents timestamp from being appended to the target folder
        [switch]$NoTimestamp,

        # Output format: png (default), webp, or avif (all lossless)
        [ValidateSet('png','webp','avif')]
        [string]$Format = 'png'
    )

    # Enable strict mode and stop on errors
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # Check if ImageMagick is installed and available in PATH
    $magickCmd = Get-Command magick -ErrorAction SilentlyContinue
    if (-not $magickCmd) {
        throw "ImageMagick 'magick' not found in PATH."
    }

    # Resolve the full path of the source image
    $Source = (Resolve-Path -LiteralPath $Source).ProviderPath

    # If -NoTimestamp is NOT set, append a timestamp to the target folder
    if (-not $NoTimestamp) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $Target = "$Target" + "_" + $timestamp
    }

    # Convert the target to an absolute path
    $Target = [IO.Path]::GetFullPath($Target)

    Write-Host "[INIT] Target folder: $Target"

    # Create the base output directory if it doesn't exist
    if ($PSCmdlet.ShouldProcess($Target, "Create output structure")) {
        New-Item -ItemType Directory -Path $Target -Force | Out-Null
    }

    # ASCII spinner frames for progress feedback
    $spinner = @('-', '\', '|', '/')
    $spinnerIndex = 0

    # Configure codec-specific arguments for lossless output
    $ext = $Format
    switch ($Format) {
        'png'  { $codecFlags = "-define png:compression-level=0" }
        'webp' { $codecFlags = "-define webp:lossless=true -quality 100" }
        'avif' { $codecFlags = "-define heic:lossless=true -quality 100" }
        default { throw "Unsupported format: $Format" }
    }

    # Loop through each zoom level
    for ($z = 0; $z -le $MaxZoom; $z++) {

        # Calculate the full image size for this zoom level
        $size  = [int]($TileSize * [math]::Pow(2, $z))

        # Number of tiles in X and Y directions
        $tiles = [int]([math]::Pow(2, $z))

        Write-Host ("[INFO] Zoom {0}: {1} x {1} pixels, {2} x {2} tiles" -f $z, $size, $tiles)
        Write-Verbose ("Creating {0} x-directories for zoom {1}" -f $tiles, $z)

        # Create zoom-level directory (e.g., Target\0)
        $zPath = Join-Path $Target $z
        if ($PSCmdlet.ShouldProcess($zPath, "Create z-level directory")) {
            New-Item -ItemType Directory -Force -Path $zPath | Out-Null
        }

        # Create subdirectories for each X coordinate
        for ($x = 0; $x -lt $tiles; $x++) {
            $xPath = Join-Path $zPath $x
            if ($PSCmdlet.ShouldProcess($xPath, "Create x directory")) {
                New-Item -ItemType Directory -Force -Path $xPath | Out-Null
            }
        }

        # Build ImageMagick arguments for this zoom level
        if ($z -eq 0) {
            # Special case for zoom 0 (single tile)
            $outFile = Join-Path (Join-Path $Target "0") (Join-Path "0" ("0." + $ext))
            $argFmt = '"{0}" -resize {1}x{1}! {2} "{3}"'
            $args = [string]::Format($argFmt, $Source, $TileSize, $codecFlags, $outFile)
        }
        else {
            # Resize the image, then crop into tiles
            $outDir = Join-Path $Target "$z"
            $argFmt = '"{0}" -resize {1}x{1}! -crop {2}x{2} -set filename:xx "%[fx:page.x/{2}]" -set filename:yy "%[fx:page.y/{2}]" +repage +adjoin {3} "{4}\%[filename:xx]\%[filename:yy].{5}"'
            $args = [string]::Format($argFmt, $Source, $size, $TileSize, $codecFlags, $outDir, $ext)
        }

        Write-Verbose ("Running magick: {0} {1}" -f $magickCmd.Source, $args)

        # Prepare ImageMagick process
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $magickCmd.Source
        $psi.Arguments = $args
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi

        try {
            # Start the external process
            [void]$process.Start()

            # Display ASCII spinner while the process is running
            while (-not $process.HasExited) {
                $frame = $spinner[$spinnerIndex]
                Write-Host -NoNewline ("`r[WORKING] {0} zoom={1}" -f $frame, $z)
                Start-Sleep -Milliseconds 150
                $spinnerIndex = ($spinnerIndex + 1) % $spinner.Length
            }

            # Read process output after completion
            $stdOut = $process.StandardOutput.ReadToEnd()
            $stdErr = $process.StandardError.ReadToEnd()

            # Handle process errors
            if ($process.ExitCode -ne 0) {
                Write-Host "`r[ERROR] Zoom $z failed".PadRight(50)
                if ($stdErr) { Write-Error ("magick stderr: " + $stdErr.Trim()) }
                throw "ImageMagick exited with code $($process.ExitCode) at zoom $z."
            }
            else {
                Write-Host ("`r[OK] Zoom {0} completed" -f $z).PadRight(50)
            }

            # Display the last modified tile file
            $lastFile = Get-ChildItem -Path $zPath -Recurse -File -ErrorAction SilentlyContinue |
                        Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($lastFile) {
                Write-Verbose ("Last file (full path): {0}" -f $lastFile.FullName)
                Write-Host ("[LAST FILE] {0}" -f $lastFile.Name)
            }
        }
        catch {
            Write-Error ("Processing failed at zoom {0}: {1}" -f $z, $_.Exception.Message)
            throw
        }
        finally {
            # Clean up process
            if ($process -and -not $process.HasExited) { $process.Kill() | Out-Null }
            $process.Dispose()
        }
    }

    Write-Host ("[OK] All zoom levels 0-{0} generated in {1}" -f $MaxZoom, $Target)

    # Return a structured object with useful metadata
    [pscustomobject]@{
        TargetPath     = $Target
        MaxZoom        = $MaxZoom
        TileSize       = $TileSize
        LevelsCreated  = $MaxZoom + 1
        Format         = $Format
        Lossless       = $true
    }
}
