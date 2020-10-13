param(
    [int] $lowerCaseLetters = 12,
    [int] $upperCaseLetters = 12,
    [int] $digits = 6
)

$lowerCaseCharacters = Get-Random -Count $lowerCaseLetters -Minimum 97 -Maximum 123
$upperCaseCharacters = Get-Random -Count $upperCaseLetters -Minimum 65 -Maximum 91
$digitCharacters = Get-Random -Count $digits -Minimum 48 -Maximum 58

$characters = ($lowerCaseCharacters + $upperCaseCharacters + $digitCharacters) | ForEach-Object { [char] $_ }
$shuffled = $characters | Get-Random -Count ([int]::MaxValue)
[string]::Join("", $shuffled)