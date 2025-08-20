```@meta
CurrentModule = SWIPL2J
```

## Prerequisites

### Windows

- Download Julia https://julialang.org/downloads/
- Download SWI-Prolog https://www.swi-prolog.org/download/stable
- Set `swipl` as an environment variable for SWI-Prolog, pointing to the directory containing `swipl.exe`
    - **Edit the system and environment variables** -> **Environment Variables...**
    - Under **User Variables** or **System Variables** Select **Path** then **Edit...**
    - Add a new environment variable by clicking **New**, then **Browse**
    - Set the new variables path to the *bin* folder for SWI-Prolog *C:\\...\swipl\bin*

### Linux

- Download Julia https://julialang.org/downloads/
- Download SWI-Prolog: `sudo apt install swi-prolog`

### MacOS

- Download Julia https://julialang.org/downloads/
- Download SWI-Prolog https://www.swi-prolog.org/download/stable


## Install SWIPL2J

At the Julia REPL, enter the package manager by pressing `]` and run:

```julia-repl
pkg> add https://github.com/Nathanlloyd7/SWIPL2J.jl
```
OR

```
pkg> add SWIPL2J
```



