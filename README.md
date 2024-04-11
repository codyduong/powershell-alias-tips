[![license](https://img.shields.io/github/license/codyduong/powershell-alias-tips.svg)](./LICENSE)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/alias-tips.svg)](https://www.powershellgallery.com/packages/alias-tips/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/alias-tips.svg)](https://www.powershellgallery.com/packages/alias-tips/)

# Alias Tips

*alias-tips* is a [PowerShell](https://microsoft.com/powershell) module dedicated to help remembering those shell aliases you once defined. Inspired by the [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh) plugin [alias-tips](https://github.com/djui/alias-tips)

The idea is that you might be too afraid to execute aliases defined because you can't remember them correctly, or just have forgotten about some aliases, or that aliases for your daily commands even exist.

## Demonstration

![Gif Demonstration of Alias Tips](./media/demo.gif)

###### Terminal is using [ `oh-my-posh` ](https://ohmyposh.dev/) w/ [ `M365Princess` ](https://ohmyposh.dev/docs/themes#m365princess), [ `git-aliases-plus` ](https://github.com/codyduong/powershell-git-aliases-plus), [ `PSReadline` ](https://github.com/PowerShell/PSReadLine)

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

## Installation and Usage

Install the module from the [PowerShell Gallery](https://www.powershellgallery.com/): 

```powershell
Install-Module alias-tips -AllowClobber
```

Inside your PowerShell profile, import alias-tips.

```powershell
Import-Module alias-tips
```

> [!IMPORTANT]
> alias-tips should be imported after all your aliases are already declared or imported

Everytime your aliases are updated or changed run [`Find-AliasTips`](./docs/en-US/Find-AliasTips.md)

```powershell
Find-AliasTips
```

This will store a hash of all aliased commands to: `$HOME/.alias_tips.hash` . It is **not recommended** to run on every profile load, as this can significantly slow down your profile startup times.

Other functionality:
- [Disable-AliasTips](./docs/en-US/Disable-AliasTips.md)
- [Enable-AliasTips](./docs/en-US/Enable-AliasTips.md)
- [Find-Alias](./docs/en-US/Find-Alias.md)
- [Find-AliasTips](./docs/en-US/Find-AliasTips.md)

## Configuration

*alias-tips* can be configured via Environment Variables

| Environment Variable             | Default Value                                            | Description                                                                               |
| :------------------------------- | :------------------------------------------------------- | :---------------------------------------------------------------------------------------- |
| ALIASTIPS_DEBUG                  | `$false`                                                 | Enable to show debug messages when processing commands                                    |
| ALIASTIPS_HASH_PATH              | `[System.IO.Path]::Combine("$HOME", '.alias_tips.hash')` | File Path to store results from `Find-AliasTips`                                          |
| ALIASTIPS_MSG                    | `"Alias tip: {0}"`                                       | Alias hint message for non-virtual terminals                                              |
| ALIASTIPS_MSG_VT                 | `` `e[033mAlias tip: {0}`em" ``                          | Alias hint message for virtual terminals*                                                 |
| ALIASTIPS_FUNCTION_INTROSPECTION | `$false`                                                 | **POTENTIALLY DESTRUCTIVE** [Function Alias Introspection](#function-alias-introspection) |

\* This uses [ANSI Escape Codes](https://en.wikipedia.org/wiki/ANSI_escape_code), for a [table of colors](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors). 
This also means alias-tips supports any other virtual terminal features: blinking/bold/underline/italics.

## How It Works

It will attempt to read all functions/aliases set in the current context. 

### Example Interactions/Limitations

#### Alias
```powershell
New-Alias -Name g -Value git
```

#### Simple Function Alias

```powershell
function grbi {
	git rebase -i $args
}
```
> [!NOTE]
> This has a limitation in that alias-tips does not know in this case that -i is equivalent to the --interactive flag.

#### Function Alias Introspection

```powershell
function gcm {
	$MainBranch = Get-Git-MainBranch

	git checkout $MainBranch $args
}
```

> [!WARNING]
> This is potentially destructive behavior

This requires backparsing as it requires running `Get-Git-MainBranch` (in this example) to get the value of `$MainBranch`.
This backparsing **could be** a destructive command is not known to alias-tips, and it will run anyways. (ie. rm, git add, etc.)

As a result this behavior is disabled by default.

Set `$env:ALIASTIPS_FUNCTION_INTROSPECTION` to `$true` to enable it.

## License

Licensed under the MIT License, Copyright © 2023-present Cody Duong.

See [LICENSE](./LICENSE) for more information.
