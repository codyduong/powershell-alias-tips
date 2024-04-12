InModuleScope 'git-aliases-plus' {
InModuleScope 'alias-tips' {
  BeforeAll {
    $env:PESTER = $true
    $env:ALIASTIPS_PESTER_FUNCTION_INTROSPECTION = $env:ALIASTIPS_FUNCTION_INTROSPECTION
    Remove-Item alias:as_s -ErrorAction SilentlyContinue
    Remove-Item function:as_f -ErrorAction SilentlyContinue
    Remove-Item function:as_f_longer -ErrorAction SilentlyContinue
    Set-Alias -Name 'as_s' -Value 'as_s_test'

    # This might cause a problem if you already aliased Out-Null

    function as_f {
      Out-Null $args
    }

    # ENSURE this remains after as_f, that way declaration order doesn't override that as_f is just a better alias recommendation
    function as_f_long {
      Out-Null $args
    }

    Find-AliasTips
  }
  Describe 'Find-Alias' {
    it 'simple alias' {
      Find-Alias 'as_s_test' |
      Should -Be 'as_s'
    }

    it 'simple function' {
      Find-Alias 'git status' |
      Should -Be 'gst'
    }

    it 'simple asf' {
      Find-Alias 'Out-Null foo' |
      Should -Be 'as_f foo'
    }

    it 'simple function args' {
      Find-Alias 'git status args' |
      Should -Be 'gst args'
    }

    it 'function introspection true' {
      $env:ALIASTIPS_FUNCTION_INTROSPECTION=$true
      Find-Alias 'git checkout master' |
      Should -Be 'gcm'
    }

    it 'function introspection false' {
      $env:ALIASTIPS_FUNCTION_INTROSPECTION=$false
      Find-Alias 'git checkout master' |
      Should -Be 'gco master'
    }

    it 'chained' {
      Find-Alias 'git status && git branch; git status; foo "$(git status)" || foo "git status"' |
      Should -Be 'gst && gb; gst; foo "$(gst)" || foo "git status"'
    }
  }

  AfterAll {
    $env:PESTER = $false
    $env:ALIASTIPS_FUNCTION_INTROSPECTION = $env:ALIASTIPS_PESTER_FUNCTION_INTROSPECTION

    Remove-Item Env:\PESTER -ErrorAction SilentlyContinue
    Remove-Item alias:as_s -ErrorAction SilentlyContinue
    Remove-Item function:as_f -ErrorAction SilentlyContinue
    Remove-Item function:as_f_long -ErrorAction SilentlyContinue

    Find-AliasTips

    Get-Job -Name "FindAliasTipsJob" -ErrorAction SilentlyContinue | Stop-Job -PassThru | Remove-Job

    # Find-AliasTips
  }
}
}