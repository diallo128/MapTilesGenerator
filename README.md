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
```

-------------------------------------------------------------------------------

## Installation

1. Clone the repository:
```powershell
git clone https://github.com/diallo128/MapTilesGenerator.git
cd MapTilesGenerator
```

2. (Optional) Allow script execution if restricted:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

3. Import or execute the script:
```powershell
. .\New-MapTiles.ps1
```

-------------------------------------------------------------------------------

## Usage

### Basic Example
```powershell
New-MapTiles -Source "C:\data\map.png" -Target "C:\tiles"
```
- Uses PNG format (default)
- Zoom levels 0..6
- Tile size 256px
- Output folder with timestamp suffix

### WebP Output
```powershell
New-MapTiles -Source ".\map.png" -Target ".\tiles" -Format webp
```

### AVIF Output Without Timestamp
```powershell
New-MapTiles -Source ".\map.png" -Target ".\tiles" -Format avif -NoTimestamp
```

### Custom Tile Size and Zoom Levels
```powershell
New-MapTiles -Source ".\map.png" -Target ".\tiles" -MaxZoom 8 -TileSize 512
```

-------------------------------------------------------------------------------

## Parameters

| Parameter       | Required | Default | Description                                                                 |
|-----------------|----------|---------|------------------------------------------------------------------------------|
| -Source         | Yes      | -       | Path to the source image file                                               |
| -Target         | Yes      | -       | Output folder for the tile structure                                        |
| -MaxZoom        | No       | 6       | Maximum zoom level (0 = single tile)                                        |
| -TileSize       | No       | 256     | Tile size in pixels                                                         |
| -NoTimestamp    | No       | Off     | Disable timestamp suffix on output folder                                   |
| -Format         | No       | png     | Output format (png, webp, avif) - all lossless                               |

-------------------------------------------------------------------------------

## Get Help in PowerShell

The script supports comment-based help. Once loaded, you can display usage help:

```powershell
Get-Help New-MapTiles -Detailed
```

or view examples directly:

```powershell
Get-Help New-MapTiles -Examples
```

-------------------------------------------------------------------------------

## Output Structure

Tiles are stored in the following structure:

```
<target-folder>/
0/
  0/
    0.png
1/
  0/
    0.png
    1.png
  1/
    0.png
    1.png
...
```

z = zoom level  
x = tile column  
y = tile row

-------------------------------------------------------------------------------

## Example Command

```powershell
New-MapTiles -Source "C:\maps\world.png" -Target "C:\output\worldtiles" -MaxZoom 6 -Format webp
```

This generates a complete set of WebP-lossless tiles from your image.

-------------------------------------------------------------------------------

## License

This project is licensed under the MIT License.

-------------------------------------------------------------------------------

## Author

Created and maintained by diallo128

-------------------------------------------------------------------------------

## Future Ideas

- Add parallel processing for large zoom levels
- Optional tile skipping for unchanged zoom levels
- Direct upload to cloud storage (for example S3)
