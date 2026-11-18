<#
.SYNOPSIS
    로또 6/45 번호 생성기

.DESCRIPTION
    1~45 중 중복 없는 6개 번호를 오름차순으로 뽑아 지정한 게임 수만큼 출력합니다.
    - 홀:짝 비율은 2:4, 3:3, 4:2만 허용
    - 합계는 22~254 범위만 허용
    - 3개 이상 연속된 번호는 제외
    난수는 암호학적으로 안전한 난수 생성기(CSPRNG)를 사용합니다.

.PARAMETER Games
    생성할 게임 수 (기본값 5)

.EXAMPLE
    .\lotto.ps1
    .\lotto.ps1 -Games 10
#>
param(
    [ValidateRange(1, 100)]
    [int]$Games = 5
)

$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

function Get-RandomIndex([int]$Max) {
    # 모듈로 편향 없이 0..Max-1 범위의 균등 난수 반환
    $limit = [uint32]::MaxValue - ([uint32]::MaxValue % [uint32]$Max)
    $bytes = New-Object byte[] 4
    do {
        $rng.GetBytes($bytes)
        $value = [BitConverter]::ToUInt32($bytes, 0)
    } while ($value -ge $limit)
    return [int]($value % [uint32]$Max)
}

function New-LottoGame {
    $pool = [System.Collections.ArrayList]@(1..45)
    $pick = @()
    for ($i = 0; $i -lt 6; $i++) {
        $k = Get-RandomIndex $pool.Count
        $pick += $pool[$k]
        $pool.RemoveAt($k)
    }
    return , @($pick | Sort-Object)
}

function Test-LottoGame([int[]]$Numbers) {
    $odd = @($Numbers | Where-Object { $_ % 2 -eq 1 }).Count
    if ($odd -lt 2 -or $odd -gt 4) { return $false }

    $sum = ($Numbers | Measure-Object -Sum).Sum
    if ($sum -le 21 -or $sum -ge 255) { return $false }

    $run = 1
    for ($i = 1; $i -lt $Numbers.Count; $i++) {
        if ($Numbers[$i] - $Numbers[$i - 1] -eq 1) { $run++ } else { $run = 1 }
        if ($run -ge 3) { return $false }
    }
    return $true
}

Write-Output "행운의 로또 번호 추천 결과입니다:"
$g = 1
while ($g -le $Games) {
    $nums = New-LottoGame
    if (-not (Test-LottoGame $nums)) { continue }

    $odd = @($nums | Where-Object { $_ % 2 -eq 1 }).Count
    $sum = ($nums | Measure-Object -Sum).Sum
    Write-Output ("- {0}게임: [ {1} ] (홀{2}:짝{3} / 합계: {4})" -f $g, ($nums -join ', '), $odd, (6 - $odd), $sum)
    $g++
}

Write-Output ""
Write-Output "로또 당첨은 완전한 무작위 확률 게임이므로, 이 번호가 당첨을 보장하지 않습니다. 가볍고 재미로만 즐겨주세요!"
