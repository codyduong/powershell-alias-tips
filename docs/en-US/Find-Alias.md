---
external help file: alias-tips-help.xml
Module Name: alias-tips
online version:
schema: 2.0.0
---

# Find-Alias

## SYNOPSIS
Finds an alias for a command string.

## SYNTAX

```
Find-Alias [-Line] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Finds an alias for a command string.
Returns the original line if no aliases are found.

## EXAMPLES

### EXAMPLE 1
```
Find-Alias "git checkout master"
```

### EXAMPLE 2
```
"git status" | Find-Alias
```

## PARAMETERS

### -Line
Specifies the line to find an alias for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String](https://docs.microsoft.com/en-us/dotnet/api/system.string)
## OUTPUTS

### [System.String](https://docs.microsoft.com/en-us/dotnet/api/system.string)
## NOTES

## RELATED LINKS
