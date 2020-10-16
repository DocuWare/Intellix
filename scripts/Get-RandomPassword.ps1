param(
    [int] $lowerCaseLetters = 12,
    [int] $upperCaseLetters = 12,
    [int] $digits = 6
)

$lowerCaseCharacters = 1..$lowerCaseLetters | ForEach-Object { Get-Random -Minimum 97 -Maximum 123 }
$upperCaseCharacters = 1..$upperCaseLetters | ForEach-Object { Get-Random -Minimum 65 -Maximum 91 }
$digitCharacters = 1..$digits | ForEach-Object { Get-Random -Minimum 48 -Maximum 58 }

$characters = ($lowerCaseCharacters + $upperCaseCharacters + $digitCharacters) | ForEach-Object { [char] $_ }
$shuffled = $characters | Get-Random -Count ([int]::MaxValue)
[string]::Join("", $shuffled)