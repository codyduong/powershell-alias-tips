InModuleScope 'alias-tips' {
  Describe 'Format-Command' {
    it 'Should not modify "" strings' {
      Format-Command " git  checkout  -b`n`"foo  bar`"  " | Should -Be "git checkout -b `"foo  bar`"" 
    }

    it "Should not modify '' strings" {
      Format-Command " git  checkout  -b`n'foo  bar'  " | Should -Be "git checkout -b 'foo  bar'" 
    }

    it 'Trim whitespace between arguments' {
      Format-Command "git     status" | Should -Be "git status"
    }

    it 'Trim command' {
      Format-Command "   git status   " | Should -Be "git status"
    }
  }
}