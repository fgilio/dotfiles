#!/usr/bin/env bash
# Sourced by bin/rm-test and bin/sublime-session-backup-test — never executed
# (tracked 644 on purpose). Counters plus the assert_* helpers; each test file
# builds its own sandbox and prints its own summary from $pass and $fail.

pass=0 fail=0

_pass() {
  ((pass++))
  printf '  \033[32mPASS\033[0m %s\n' "$1"
}

_fail() {
  ((fail++))
  printf '  \033[31mFAIL\033[0m %s\n' "$1"
}

# assert_pass DESC CMD...: CMD exits 0
assert_pass() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then _pass "$desc"; else _fail "$desc"; fi
}

# assert_fail DESC CMD...: CMD exits non-zero
assert_fail() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then _fail "$desc (expected failure)"; else _pass "$desc"; fi
}

# assert_stderr DESC PATTERN CMD...: CMD exits non-zero and PATTERN is in its stderr
assert_stderr() {
  local desc="$1" pattern="$2"
  shift 2
  local err rc
  err="$("$@" 2>&1 >/dev/null)" && rc=0 || rc=$?
  if [[ $rc -ne 0 && "$err" == *"$pattern"* ]]; then
    _pass "$desc"
  else
    _fail "$desc (rc=$rc, expected \"$pattern\" in stderr, got \"$err\")"
  fi
}

# Like assert_stderr but doesn't require non-zero exit (for info/verbose messages)
assert_stderr_any() {
  local desc="$1" pattern="$2"
  shift 2
  local err
  err="$("$@" 2>&1 >/dev/null)" || true
  if [[ "$err" == *"$pattern"* ]]; then
    _pass "$desc"
  else
    _fail "$desc (expected \"$pattern\" in stderr, got \"$err\")"
  fi
}

assert_exists() {
  local desc="$1" path="$2"
  if [[ -e "$path" || -L "$path" ]]; then _pass "$desc"; else _fail "$desc (not found: $path)"; fi
}

assert_not_exists() {
  local desc="$1" path="$2"
  if [[ ! -e "$path" && ! -L "$path" ]]; then _pass "$desc"; else _fail "$desc (should not exist: $path)"; fi
}

# assert_eq DESC WANT GOT
assert_eq() {
  local desc="$1" want="$2" got="$3"
  if [[ "$want" == "$got" ]]; then _pass "$desc"; else _fail "$desc (want \"$want\", got \"$got\")"; fi
}

# assert_file_has DESC FIXED-STRING FILE
assert_file_has() {
  local desc="$1" needle="$2" file="$3"
  if grep -qF -- "$needle" "$file" 2>/dev/null; then _pass "$desc"; else _fail "$desc (\"$needle\" not in $file)"; fi
}
