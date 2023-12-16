[![license](https://img.shields.io/github/license/codyduong/powershell-alias-tips.svg)](./LICENSE)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/alias-tips.svg)](https://www.powershellgallery.com/packages/alias-tips/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/alias-tips.svg)](https://www.powershellgallery.com/packages/alias-tips/)

# Alias Tips

*Alias-Tips* is a [PowerShell](https://microsoft.com/powershell) module dedicated to help remembering those shell aliases and Git aliases you once defined. Inspired by the [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh) plugin [alias-tips](https://github.com/djui/alias-tips)

The idea is that you might be too afraid to execute aliases defined because you can't remember them correctly, or just have forgotten about some aliases, or that aliases for your daily commands even exist.

## Demonstration

![Gif Demonstration of Alias Tips](./media/demo.gif)

###### Terminal is using [ `oh-my-posh` ](https://ohmyposh.dev/) with [ `M365Princess` ](https://ohmyposh.dev/docs/themes#m365princess) theme and [`git-aliases-plus`](https://github.com/codyduong/powershell-git-aliases-plus) for git aliases

------------------

```powershell
$ git status
Alias tip: gst
:

$ git checkout -b master
Alias tip: gcb master
:

$ git rebase --interactive master
Alias tip: grb --interactive master
:

$ git rebase -i master
Alias tip: grbi master
:

$ Move-Item foo bar
Alias tip: mv foo bar
:
```

View [Caveats](#caveats)

## Installation

Install from PowerShell Gallery

```powershell
Install-Module alias-tips -AllowClobber
```

## Usage

```powershell
# After declaring all your aliases, import this module
Import-Module alias-tips
```

Everytime your aliases are updated run:
```powershell
Find-AliasTips
```

You **should not run** `Find-AliasTips` everytime your profile is loaded. 
It is an expensive operation, which first parses every possible command in the
current shell context and then 
commands and their associated aliases in a file at `$HOME/.alias-tips-hash`

## Configuration
### Hardcore Mode
This will prevent any commands from running and instead prompt you to use the alias

### Color/Text
Alias-tips uses `Out-Host` instead of `Write-Host`. 
It also means colors will only work if VT (Virtual Terminal) is enabled. 
As a consequence, in order to color the text we require ANSI Color Escape sequences 
instead of the more familiar `[Enum]::GetValues([ConsoleColor])` values.

By default we use orange:
```powershell
$AliasTipsColor = '033m'
Import-Module alias-tips
```

## Caveats

### Limited Aliasing Power

This tool will read all available aliases including custom aliases defined using the `function` syntax.
However, it is limited and naive in it's approach.

### Example Alias Tip Interactions

#### ✅ Simple Function Alias
```powershell
function grbi {
	git rebase -i $args
}
```
**NOTE**: Alias-tips right now has no way of knowing `-i` is equivalent to `--interactive`.

#### ✅ Function Alias with simple variable assignment
```powershell
function gcm {
	$MainBranch = Get-Git-MainBranch

	git checkout $MainBranch $args
}
```
#### ❌ Function Alias with variables dependent on `$args`
```powershell
function someAlias {
	$OtherArgs = $args | ForEach-Object {
		$_.key
	}

	someCommand $OtherArgs
}
```

#### ❌ Function Alias with complex variable assignment
```powershell
function someAlias {
	$A = "foobar"
	$B = $A + " $args"

	someCommand $B
}
```
**NOTE**: Complex in this manner referring to the multi-step assignment.

### Overwrites `function PSConsoleHostReadLine`

Be aware if you use `function PSConsoleHostReadLine` as part of another module or your PowerShell profile, 
alias-tips will break it.

## License

Licensed under the MIT License, Copyright © 2023-present Cody Duong.

See [LICENSE](./LICENSE) for more information.
