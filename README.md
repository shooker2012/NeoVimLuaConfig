# NeoVim安装步骤

## 1. [安装NeoVim](https://github.com/neovim/neovim/releases/latest/download/nvim-win64.msi)

## 2. 配置NeoVim
将https://github.com/shooker2012/NeoVimLuaConfig Clone到%localappdata%/nvim中

'''git clone https://github.com/shooker2012/NeoVimLuaConfig.git %localappdata%/nvim'''

## 3. 安装相关软件

### 3.1 [Python3](https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe)

安装完成后：

#### 3.1.1 设置$PATH

安装python3安装后，将exe目录添加到$PATH，并设置为较高等级。（否则, 命令行下python会找到windows商店中的python）

#### 3.1.2 为neovim安装pyvim

'''pip3 install pynvim'''

~~'''python3 -m pip install --user --upgrade pynvim'''~~

### 3.2 [node.js](https://nodejs.org/en/download/)


### 3.3 ripgrep

【依赖插件】 Telescope

#### 安装

[Releases · BurntSushi/ripgrep (github.com)](https://github.com/BurntSushi/ripgrep/releases)

安装pc-windows-msvc.zip版本即可。

### 3.4 zig

【依赖插件】Treesitter

#### 安装

[Download ⚡ Zig Programming Language (ziglang.org)](https://ziglang.org/download/)

安装x86_64即可。

安装后，需要将exe所在目录添加到环境变量$PATH中。
