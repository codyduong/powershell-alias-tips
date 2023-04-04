function Get-CommandsPattern {
  (Get-Command * | ForEach-Object {
    $CommandUnsafe = $_ | Select-Object -ExpandProperty 'Name'
    $Command = [Regex]::Escape($CommandUnsafe)
    # check if it has a file extensions
    if ($CommandUnsafe -match "(?<cmd>[^.\s]+)\.(?<ext>[^.\s]+)$") {
      $CommandWithoutExtension = [Regex]::Escape($matches['cmd'])
      return $Command, $CommandWithoutExtension
    } else {
      return $Command
    }
  }) -Join '|'
}

$global:AliasTipCommandsPattern = Get-CommandsPattern

# THANKS TO csc027 for the original code https://github.com/csc027
# Taken from: https://github.com/dahlbyk/posh-git/blob/ad8278e90ad8180c18e336676e490d921615e506/src/GitTabExpansion.ps1#L73-L87
#
# The regular expression here is roughly follows this pattern:
#
# <begin anchor><whitespace>*<command>(<whitespace><parameter>)*<whitespace>+<$args><whitespace>*<end anchor>
#
# The delimiters inside the parameter list and between some of the elements are non-newline whitespace characters ([^\S\r\n]).
# In those instances, newlines are only allowed if they preceded by a non-newline whitespace character.
#
# Begin anchor (^|[;`n])
# Whitespace   (\s*)
# Any Command  (?<cmd>)
# Parameters   (?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)
# $args Anchor (([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)
# Whitespace   (\s|``\r?\n)*
# End Anchor   ($|[|;`n])
function Get-ProxyFunctionRegex {
  param (
    [Parameter(Mandatory, ValueFromPipeline = $true)][string]${CommandPattern}
  )

  "(^|[;`n])(\s*)(?<cmd>($CommandPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(([^\S\r\n]|[^\S\r\n]``\r?\n)+\`$args)(\s|``\r?\n)*($|[|;`n])"
} 
function Get-ProxyFunctionRegexNoArgs {
  param (
    [Parameter(Mandatory, ValueFromPipeline = $true)][string]${CommandPattern}
  )

  "(^|[;`n])(\s*)(?<cmd>($CommandPattern))(?<params>(([^\S\r\n]|[^\S\r\n]``\r?\n)+\S+)*)(\s|``\r?\n)*($|[|;`n])"
}

function Format-CleanCommand {
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)][string]${Command}
  )

  return ($Command -replace '`\r?\n', ' ' -replace '\s+', ' ').Trim()
}

# Returns a regex to match with
function Get-CommandMatcher {
  param(
    [Parameter(Mandatory, ValueFromPipeline = $true)][string]${Command},
    [Parameter()][switch]${Simple}
  )

  if ($Simple) {
    $CleanCommand = $Command | Format-CleanCommand
    return "(" + ([Regex]::Escape($CleanCommand) -split " " -join "|") + ")"
  }

  # The parse is a bit naive...
  if ($Command -match $AliasTipsProxyFunctionRegexNoArgs) {
    # Clean up the command by removing extra delimiting whitespace and backtick preceding newlines
    $CommandString = ("$($matches['cmd'].TrimStart())") | Format-CleanCommand

    $ReqParams = $($matches['params']) -split " "
    # $ReqParamLength = $ReqParams.Count
    $ReqParamRegex = "(" + ($ReqParams.ForEach({
          "$([Regex]::Escape($_.Trim()))(\s|``\r?\n)*"
        }) -join '|') + ")*"

    # Enable sensitive case (?-i)
    # Begin anchor      (^|[;`n])
    # Whitespace        (\s*)
    # Any Command       (?<cmd>$CommandString)
    # Whitespace        (\s|``\r?\n)*
    # Req Parameters    (?<params>$ReqParamRegex)
    # Req Param Length  {$ReqParamLength,}
    # Whitespace        (\s|``\r?\n)*
    # End Anchor        ($|[|;`n])
    #$Regex = "(^|[;`n])(\s*)(?<cmd>$CommandString)(?<params>$ReqParamRegex{$ReqParamLength,})(\s|``\r?\n)*($|[|;`n])"
    $Regex = "(?-i)(^|[;`n])(\s*)(?<cmd>$CommandString)(\s|``\r?\n)*(?<params>$ReqParamRegex)(\s|``\r?\n)*($|[|;`n])"

    return $Regex
  }

  return ""
}

$script:AUTOMATIC_VARIBLES_TO_SUPRESS = @(
  '\$',
  '\?',
  '\^',
  '_',
  'args',
  'ConsoleFileName',
  'EnabledExperimentalFeatures',
  'Error',
  'Event(Args|Subscriber)?',
  'ExecutionContext',
  'false',
  'HOME',
  'Host',
  'input',
  'Is(CoreCLR|Linux|MacOS|Windows){1}',
  'LASTEXITCODE',
  'Matches', # TODO?
  'MyInvocation',
  'NestedPromptLevel',
  'null',
  'PID',
  'PROFILE',
  'PSBoundParameters', # TODO?
  'PSCmdlet',
  'PSCommandPath', # TODO?
  'PSCulture',
  'PSDebugContext',
  'PSEdition',
  'PSHOME',
  'PSItem',
  'PSScriptRoot',
  'PSSenderInfo',
  'PSUICulture',
  'PSVersionTable',
  'PWD',
  'Sender',
  'ShellId',
  'StackTrace',
  'switch',
  'this',
  'true'
) -Join '|'

# Finds the command based on the alias and replaces $(...) if possible
function Format-CommandAST {
  param(
    [Parameter(Mandatory)][string]${Alias}
  )

  # Get the original definition
  $Def = Get-Item -Path Function:\$Alias | Select-Object -ExpandProperty 'Definition'

  # Find variables we need to resolve, ie $MainBranch
  $VarsToResolve = @("")
  $ReconstructedCommand = ""
  if ($Def -match $AliasTipsProxyFunctionRegexNoArgs) {
    $ReconstructedCommand = ("$($matches['cmd'].TrimStart()) $($matches['params'])") | Format-CleanCommand
    if ($args -match '\$args') {
      $ReconstructedCommand += ' $args'
    }
    $($matches['params'] | Format-CleanCommand) -split " " | ForEach-Object {
      if ($_ -match '\$') {
        # Make sure it is not an automatic variable
        if ($_ -match  "(\`$)($AUTOMATIC_VARIBLES_TO_SUPRESS)") {

        } else {
          $VarsToResolve += $_ -replace "[^$`n]*(?=\$)", ""
        }
      }
    }
  } else {
    return ""
  }

  $VarsReplaceHash = @{}
  Get-Variable AliasTipsInternalASTResults_* | ForEach-Object {
    if ($_.Value) {
      $VarsReplaceHash[$($_.Name -replace "AliasTipsInternalASTResults_","")] = $_.Value
    }
  }

  # If there are vars to resolve, attempt to find them.
  if ($VarsToResolve) {
    $DefScriptBlock = [scriptblock]::Create($Def)
    $DefAst = $DefScriptBlock.Ast

    foreach ($Var in $VarsToResolve) {
      # Attempt to find the definition based on the ast
      # TODO: handle nested script blocks
      $FoundAssignment = $DefAst.Find({
        $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and
        $("$($args[0].Extent)" -eq "$Var")
      }, $false)
      if ($FoundAssignment -and -not $VarsReplaceHash[$Var]) {
        $CommandToEval = $($FoundAssignment.Parent -replace "[^=`n]*=","").Trim()
        # Super naive LOL! Hopefully the command isn't destructive!
        $Evaluated = Invoke-Command -ScriptBlock $([scriptblock]::Create("$CommandToEval -ErrorAction SilentlyContinue"))
        if ($Evaluated) {
          $VarsReplaceHash[$Var] = $Evaluated
          Set-Variable -Name "AliasTipsInternalASTResults_$Var" -Value $Evaluated -Scope Global
        }
      }
    }

    $VarsReplaceHash.GetEnumerator() | ForEach-Object {
      if ($_.Value) {
        $ReconstructedCommand = $ReconstructedCommand -replace $([regex]::Escape($_.key)),$_.Value
      }
    }

    return $($ReconstructedCommand | Format-CleanCommand)
  }
}

function Clear-AliasTipsInternalASTResults {
  Clear-Variable AliasTipsInternalASTResults_* -Scope Global
}
