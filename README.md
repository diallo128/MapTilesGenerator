# MapTilesGenerator

MapTilesGenerator is a lightweight PowerShell script that converts a single raster image into a tiled map structure (z/x/y layout).  
It uses ImageMagick for image processing and supports PNG, WebP and AVIF formats - all in lossless mode.

-------------------------------------------------------------------------------

## Features

- Generates tiles in standard z/x/y structure
- Adjustable zoom levels and tile size
- Supports PNG (default), WebP-lossless and AVIF-lossless
- ASCII-only console output (works well in terminals)
- Minimal dependencies: only PowerShell and ImageMagick
- Fully documented function with comment-based help (Get-Help)

-------------------------------------------------------------------------------

## Requirements

- Windows PowerShell 5.1 or later
- ImageMagick (magick must be available in PATH)

Check if ImageMagick is installed:
```powershell
magick -version
