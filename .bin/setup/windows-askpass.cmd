@echo off
REM Answers git's credential prompts on the WINDOWS side, non-interactively.
REM
REM Windows git's credential helper is GCM, which holds no github.com login on a
REM machine set up from WSL and cannot prompt for one with no console attached.
REM Git then falls back to its built-in terminal prompt, which needs /dev/tty and
REM dies with "No such device or address" - taking the whole clone down with it.
REM GIT_ASKPASS is the documented hook for exactly that fallback.
REM
REM The token is read from the environment, never stored here: windows.sh puts it
REM in DOTFILES_GH_TOKEN and WSLENV forwards it into the Windows process.
REM
REM Git passes the prompt text as the argument, e.g.
REM   Username for 'https://github.com':
REM   Password for 'https://x-access-token@github.com':
REM
REM The match is cmd's own substring substitution rather than `find "Username"`.
REM Git invokes this from an environment whose PATH leads with git's msys bin, so
REM `find` there is GNU find, not C:\Windows\System32\find.exe - it rejected /I as
REM a missing file, the test always failed, and the token was returned for the
REM USERNAME prompt as well. That happened to authenticate anyway, since GitHub
REM accepts a token as the username, so the bug was invisible in a passing run.
REM %~1, not %* : %* keeps the caller's surrounding double quotes, which then
REM unbalance the quotes in the comparison below and make cmd fail on the literal
REM text of the prompt ("for was unexpected at this time").
setlocal
set "ASKPASS_PROMPT=%~1"
if not "%ASKPASS_PROMPT%"=="%ASKPASS_PROMPT:Username=%" (
    echo x-access-token
) else (
    echo %DOTFILES_GH_TOKEN%
)
