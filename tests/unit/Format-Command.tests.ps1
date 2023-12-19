InModuleScope 'alias-tips' {
  Describe 'Format-Command' {
    it 'Should not modify "" strings' {
      Format-Command " git  checkout  -b`n`"foo  bar`"  " | Should -Be "git checkout -b `"foo  bar`"" 
    }

    it 'Should not modify '' strings' {
      Format-Command " git  checkout  -b`n'foo  bar'  " | Should -Be "git checkout -b 'foo  bar'" 
    }
  }
}