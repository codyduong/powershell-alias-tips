[![license](https://img.shields.io/github/license/codyduong/powershell-alias-tips.svg)](./LICENSE)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/alias-tips.svg)](https://www.powershellgallery.com/packages/alias-tips/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/alias-tips.svg)](https://www.powershellgallery.com/packages/alias-tips/)

# Alias Tips

*Alias-Tips* is a [PowerShell](https://microsoft.com/powershell) module dedicated to help remembering those shell aliases you once defined. Inspired by the [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh) plugin [alias-tips](https://github.com/djui/alias-tips)

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

## Installation and Usage

Install from PowerShell Gallery

```powershell
Install-Module alias-tips -AllowClobber
```

## Usage

Inside your PowerShell profile
```powershell
Import-Module alias-tips
```

Everytime your aliases are updated run `Find-AliasTips`. This will store a hash of all aliases
to default: `$HOME/.alias_tips.hash`. View [Configuration][#configuration] to 

## Configuration
*alias-tips* can be configured via Environment Variables
```powershell
# Set the template message (Note the distinction between non virtual terminal and virtual terminal supported template strings
$env:ALIASTIPS_MSG = "" # Default: "Alias tip: {0}"
$env:ALIASTIPS_MSG_VT = "" # Default: "`e[033mAlias tip: {0}`e[m"

# Set the alias hash location
$env:ALIASTIPS_HASH_PATH = "" # Default: [System.IO.Path]::Combine("$HOME", '.alias_tips.hash')

# Debug and other values
$env:ALIASTIPS_DEBUG = "" # Default: $false
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
