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
function Format-CommandFromExecutionContext {
  param(
    [Parameter(Mandatory)][string]${Alias}
  )

  # Get the original definition
  $Def = Get-Item -Path Function:\$Alias | Select-Object -ExpandProperty 'Definition'

  # Find variables we need to resolve, ie $MainBranch
  $VarsToResolve = @("")
  $ReconstructedCommand = ""
  if ($Def -match $AliasTipsProxyFunctionRegexNoArgs) {
    $ReconstructedCommand = ("$($matches['cmd'].TrimStart()) $($matches['params'])") | Format-Command
    if ($args -match '\$args') {
      $ReconstructedCommand += ' $args'
    }
    $($matches['params'] | Format-Command) -split " " | ForEach-Object {
      if ($_ -match '\$') {
        # Make sure it is not an automatic variable
        if ($_ -match "(\`$)($AUTOMATIC_VARIBLES_TO_SUPRESS)") {

        }
        else {
          $VarsToResolve += $_ -replace "[^$`n]*(?=\$)", ""
        }
      }
    }
  }
  else {
    return ""
  }

  $VarsReplaceHash = @{}
  Get-Variable AliasTipsInternalASTResults_* | ForEach-Object {
    if ($_.Value) {
      $VarsReplaceHash[$($_.Name -replace "AliasTipsInternalASTResults_", "")] = $_.Value
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
        $CommandToEval = $($FoundAssignment.Parent -replace "[^=`n]*=", "").Trim()
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
        $ReconstructedCommand = $ReconstructedCommand -replace $([regex]::Escape($_.key)), $_.Value
      }
    }

    return $($ReconstructedCommand | Format-Command)
  }
}