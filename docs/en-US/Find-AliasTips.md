---
external help file: alias-tips-help.xml
Module Name: alias-tips
online version:
schema: 2.0.0
---

# Find-AliasTips

## SYNOPSIS
Finds alias-tips for the current shell context.

## SYNTAX

```
Find-AliasTips
```

## DESCRIPTION
Finds alias-tips for the current shell context.
This command should be run everytime aliases 
are updated or changed.
It caches the expensive operation to a pipe delimited file in the 
`$env:AliasTipsHashFile` location.
By default this location is at `$HOME/.alias_tips.hash`.

## EXAMPLES

### EXAMPLE 1
```
Find-AliasTips
```

## PARAMETERS

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
