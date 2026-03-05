# Created: 2026.03.05
# Author: <VladVons@gmail.com>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Api($aData)
{
    $DataJson = $aData | ConvertTo-Json -Compress
    $File=$aData['type'] + '.json'

    Invoke-WebRequest "https://windows.cloud-server.com.ua/api" `
        -Method POST `
        -ContentType "application/json" `
        -Body $DataJson |
    Select-Object -ExpandProperty Content |
    ConvertFrom-Json |
    ConvertTo-Json -Depth 100 |
    ForEach-Object { $_ -replace '    ', '  ' } |
    Set-Content $File -Encoding UTF8
}

$Data = @{
  type = 'get_licences_user'
  app  = 'vBuhAssist'
  #date = '2026-03-05'
  user = 'yuta'
  passw = 'xxxx'
}
Api $Data
