Set-StrictMode -Off
Add-Type -AssemblyName System.Drawing

$dir     = 'c:\Users\RajaShanmugam\OneDrive - ConceptVines\Desktop\Applications\PV website\Main'
$srcImg  = Join-Path $dir 'prepvicta_high_quality_transparent.png'
$htmlFile = Join-Path $dir 'index.html'

# ── Embed fast C# pixel processor ──────────────────────────────────
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class LogoFix {
    // Remove black background and clip circular border in one pass
    public static void Process(string inputPath, string outputPath,
                               int blackThreshold, double borderFraction) {
        Image srcImg = Image.FromFile(inputPath);
        Bitmap bmp   = new Bitmap(srcImg.Width, srcImg.Height,
                                  PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp))
            g.DrawImage(srcImg, 0, 0, srcImg.Width, srcImg.Height);
        srcImg.Dispose();

        double cx    = bmp.Width  / 2.0;
        double cy    = bmp.Height / 2.0;
        double maxR  = Math.Min(cx, cy);
        double clipR = maxR * (1.0 - borderFraction);
        double clipR2 = clipR * clipR;

        BitmapData bd = bmp.LockBits(
            new Rectangle(0, 0, bmp.Width, bmp.Height),
            ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);

        int stride = Math.Abs(bd.Stride);
        byte[] buf = new byte[stride * bmp.Height];
        Marshal.Copy(bd.Scan0, buf, 0, buf.Length);

        for (int y = 0; y < bmp.Height; y++) {
            double dy2 = (y - cy) * (y - cy);
            int row = y * stride;
            for (int x = 0; x < bmp.Width; x++) {
                double dx = x - cx;
                int i = row + x * 4;
                // Outside content circle -> transparent (removes border)
                if (dx * dx + dy2 > clipR2) { buf[i+3] = 0; continue; }
                // Near-black pixels -> transparent (removes background)
                if (buf[i] < blackThreshold &&
                    buf[i+1] < blackThreshold &&
                    buf[i+2] < blackThreshold) { buf[i+3] = 0; }
            }
        }

        Marshal.Copy(buf, 0, bd.Scan0, buf.Length);
        bmp.UnlockBits(bd);
        bmp.Save(outputPath, ImageFormat.Png);
        bmp.Dispose();
    }

    // High-quality resize to target w x h
    public static void Resize(string inputPath, string outputPath, int w, int h) {
        using (Image src = Image.FromFile(inputPath)) {
            using (Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb)) {
                using (Graphics g = Graphics.FromImage(bmp)) {
                    g.InterpolationMode  =
                        System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    g.SmoothingMode      =
                        System.Drawing.Drawing2D.SmoothingMode.HighQuality;
                    g.PixelOffsetMode    =
                        System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                    g.CompositingQuality =
                        System.Drawing.Drawing2D.CompositingQuality.HighQuality;
                    g.DrawImage(src, 0, 0, w, h);
                }
                bmp.Save(outputPath, ImageFormat.Png);
            }
        }
    }
}
"@ -ReferencedAssemblies 'System.Drawing'
Write-Host 'C# compiled.'

# ── Step 1: Process full-res logo (remove black bg + clip border) ──
$tmp = Join-Path $dir '_logo_processed.png'
Write-Host 'Processing 8192x8192 logo — removing black background and border...'
# blackThreshold=25 removes near-black pixels; borderFraction=0.05 clips outer 5% ring (the border)
[LogoFix]::Process($srcImg, $tmp, 25, 0.05)
Write-Host 'Done processing.'

# ── Step 2: Create sized outputs ───────────────────────────────────
Write-Host 'Generating sizes...'
[LogoFix]::Resize($tmp, (Join-Path $dir 'logo.png'),            200, 200)
[LogoFix]::Resize($tmp, (Join-Path $dir 'favicon-32x32.png'),   32,  32 )
[LogoFix]::Resize($tmp, (Join-Path $dir 'favicon-16x16.png'),   16,  16 )
[LogoFix]::Resize($tmp, (Join-Path $dir 'apple-touch-icon.png'),180, 180)
Remove-Item $tmp -Force
Write-Host '  logo.png (200x200), favicon-32x32.png, favicon-16x16.png, apple-touch-icon.png'

# ── Step 3: Rebuild favicon.ico (16+32 PNG-in-ICO) ─────────────────
$png16 = [System.IO.File]::ReadAllBytes((Join-Path $dir 'favicon-16x16.png'))
$png32 = [System.IO.File]::ReadAllBytes((Join-Path $dir 'favicon-32x32.png'))
$ms    = New-Object System.IO.MemoryStream

$ms.Write([byte[]]@(0,0,1,0,2,0), 0, 6)   # ICONDIR header
$off16 = [int32]38
$off32 = [int32]($off16 + $png16.Length)

foreach ($entry in @(@(16,$off16,$png16.Length), @(32,$off32,$png32.Length))) {
    $sz = $entry[0]
    $ms.WriteByte($sz); $ms.WriteByte($sz); $ms.WriteByte(0); $ms.WriteByte(0)
    $ms.Write([System.BitConverter]::GetBytes([int16]1),  0, 2)
    $ms.Write([System.BitConverter]::GetBytes([int16]32), 0, 2)
    $ms.Write([System.BitConverter]::GetBytes([int32]$entry[2]), 0, 4)
    $ms.Write([System.BitConverter]::GetBytes([int32]$entry[1]), 0, 4)
}
$ms.Write($png16, 0, $png16.Length)
$ms.Write($png32, 0, $png32.Length)
[System.IO.File]::WriteAllBytes((Join-Path $dir 'favicon.ico'), $ms.ToArray())
$ms.Dispose()
Write-Host "  favicon.ico ($((Get-Item (Join-Path $dir 'favicon.ico')).Length) bytes)"

# ── Step 4: Update index.html ───────────────────────────────────────
$html = [System.IO.File]::ReadAllText($htmlFile, [System.Text.Encoding]::UTF8)

# Update navbar logo to new transparent file
$html = $html.Replace('src="prepvicta_high_quality_transparent.png"', 'src="logo.png"')

# Fix favicon paths: remove leading slash so they work locally AND on server
$html = $html.Replace('href="/favicon.ico"',        'href="favicon.ico"')
$html = $html.Replace('href="/favicon-32x32.png"',  'href="favicon-32x32.png"')
$html = $html.Replace('href="/favicon-16x16.png"',  'href="favicon-16x16.png"')
$html = $html.Replace('href="/apple-touch-icon.png"','href="apple-touch-icon.png"')

[System.IO.File]::WriteAllText($htmlFile, $html, [System.Text.Encoding]::UTF8)
Write-Host '  index.html updated (logo + favicon paths)'

Write-Host ''
Write-Host 'All done.'
Get-ChildItem $dir | Where-Object { $_.Name -match '^(logo|favicon|apple)' -and $_.Extension -ne '.ps1' } |
    Format-Table Name, @{L='Size';E={$_.Length}} -AutoSize
