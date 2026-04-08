# Briefer Agent: Implementation Tweaks & Recommendations

## Summary

This document provides concrete recommendations to improve the safety, portability, and correctness of the briefer agent's pseudocode and implementation, based on recent analysis and test runs.

## Key Recommendations

1. **Enable Variable Expansion in Here-Doc**
   - Change the here-doc opener from `<<'EOF'` to `<<EOF` to allow `${NUMTOKENS}` and `${focus_sanitized}` to expand in the output file.

2. **Check mktemp Success**
   - After calling `mktemp`, immediately check its exit status and fail if it did not succeed:
     ```bash
     tmp="$(mktemp "${outdir}/.brief.${NUMTOKENS}.XXXXXX")" || { echo "mktemp failed" >&2; exit 5; }
     ```

3. **Add Strict Shell Options**
   - Add `set -euo pipefail` near the top to abort on errors and catch unset variables.

4. **Sanitize and Validate Inputs**
   - Improve focus sanitization to collapse multiple invalid characters and trim leading/trailing dots/hyphens:
     ```bash
     focus_sanitized="$(printf '%s' "${focus_raw}" | sed -E 's/[^A-Za-z0-9._-]+/-/g' | sed -E 's/^[._-]+|[._-]+$//g')"
     ```
   - Add a numeric bounds check for `NUMTOKENS` (e.g., 1–20000):
     ```bash
     if [ "${NUMTOKENS}" -lt 1 ] || [ "${NUMTOKENS}" -gt 20000 ]; then echo "token count out of bounds: ${NUMTOKENS}" >&2; exit 2; fi
     ```

5. **Make Output Directory Absolute**
   - Resolve `outdir` relative to the repository root to avoid accidental writes in the wrong location.

6. **Document All Assumptions**
   - Clearly state that the script must be run from the repo root or set `repo_root` explicitly.

## Example: Corrected Pseudocode Snippet

```bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
outdir="${repo_root}/specs/prompts"
mkdir -p "${outdir}" || { echo "Failed to create ${outdir}" >&2; exit 3; }
# ... (parse NUMTOKENS and focus_sanitized as above)
tmp="$(mktemp "${outdir}/.brief.${NUMTOKENS}.XXXXXX")" || { echo "mktemp failed" >&2; exit 5; }
cat > "${tmp}" <<EOF
# ... content with expanded variables ...
EOF
mv -f "${tmp}" "${outfile}" || { rm -f "${tmp}"; echo "Failed to move ${tmp} -> ${outfile}" >&2; exit 4; }
```

## Rationale

These changes ensure that the briefer agent:
- Always expands variables in output
- Fails safely on temp file errors
- Avoids accidental hidden or invalid filenames
- Is robust to directory context
- Is portable across Unix-like systems

**Adopt these tweaks for all future briefer agent implementations.**
