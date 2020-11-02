#!/bin/bash

lowerCaseLetters=12
upperCaseLetters=12
digits=6

while [ $# -gt 0 ]; do
  case "$1" in
  --lower-case-letters=*)
    lowerCaseLetters="${1#*=}"
    ;;
  --upper-case-letters=*)
    upperCaseLetters="${1#*=}"
    ;;
  --digits=*)
    digits="${1#*=}"
    ;;
  *) ;;
  esac
  shift
done

upperCaseCharacters=$(head /dev/urandom | tr -dc A-Z | head -c $upperCaseLetters)
lowerCaseCharacters=$(head /dev/urandom | tr -dc a-z | head -c $lowerCaseLetters)
digitCharacters=$(head /dev/urandom | tr -dc 0-9 | head -c $digits)
echo "$upperCaseCharacters$lowerCaseCharacters$digitCharacters" | sed 's/./&\n/g' | shuf | tr -d "\n"
