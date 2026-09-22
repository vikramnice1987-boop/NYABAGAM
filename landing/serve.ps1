# NYABAGAM Landing Page Local Web Server (Pure PowerShell / .NET HttpListener)
$port = 8080
$dir = $PSScriptRoot

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " NYABAGAM (ஞாபகம்) Web Landing Page Preview Server" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Local URL:  http://localhost:$port/index.html" -ForegroundColor Green
Write-Host "Directory:  $dir" -ForegroundColor DarkGray
Write-Host "Press Ctrl+C in this terminal to stop the server." -ForegroundColor Yellow
Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray

Start-Process "http://localhost:$port/index.html"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($path)) {
            $path = "index.html"
        }

        $localPath = Join-Path $dir $path
        if (-not (Test-Path $localPath) -or (Get-Item $localPath).PSIsContainer) {
            $localPath = Join-Path $dir "index.html"
        }

        if (Test-Path $localPath) {
            $bytes = [System.IO.File]::ReadAllBytes($localPath)
            $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
            $contentType = switch ($ext) {
                ".html" { "text/html; charset=utf-8" }
                ".css"  { "text/css; charset=utf-8" }
                ".js"   { "application/javascript; charset=utf-8" }
                ".png"  { "image/png" }
                ".svg"  { "image/svg+xml" }
                ".apk"  { "application/vnd.android.package-archive" }
                default { "application/octet-stream" }
            }
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.AddHeader("Access-Control-Allow-Origin", "*")
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
