#!/bin/bash
# Flags writing tells in a draft.
#   hard: dashes used as pauses, semicolons, curly or mismatched quotes, Unicode
#         arrows, middle-dot separators, stock AI phrases. Exit 1 on any.
#   warn: shapes that are usually tells (colon reveals, closing morals, brief
#         echoes, one-sentence paragraph runs, German calques). Printed, exit 0.
#
# Usage: check-tells.sh [--de] [--fiction] [--brief FILE] FILE...|-
#   --fiction     story prose: also warn on runs of very short sentences, withheld-knowledge
#                 lines, body-part familiarity similes, resume numbers, a long first
#                 sentence and more than two "like"/"as if" comparisons.
#   --de          German text: „…“ quotes allowed (and checked for pairing), German rules added.
#   --brief FILE  also warn on every run of 5+ words shared with the brief.
# Prints "file:line: rule: match" per hit. Exit 0 if no hard hit, 1 on any, 2 on bad input.
# Fenced code blocks and `inline code` are skipped, so commands like "git checkout -- x" pass.
# The curly quotes in the rules are the characters being searched for.
# shellcheck disable=SC1111
set -uo pipefail
export LC_ALL=C.UTF-8

de=0 fiction=0 brief=
while [[ $# -gt 0 ]]; do
  case $1 in
    --de) de=1; shift ;;
    --fiction) fiction=1; shift ;;
    --brief) brief=${2:-}; shift 2 || { echo "check-tells.sh: --brief needs a file" >&2; exit 2; } ;;
    *) break ;;
  esac
done
if [[ $# -eq 0 ]]; then
  echo "usage: check-tells.sh [--de] [--fiction] [--brief FILE] FILE...|-" >&2
  exit 2
fi
if [[ -n $brief && ! -r $brief ]]; then
  echo "check-tells.sh: cannot read brief $brief" >&2
  exit 2
fi

# Each entry is "severity<TAB>grep flags<TAB>rule name<TAB>regex".
# Flags: -E extended, -P perl; add -i for case-insensitive.
T=$'\t'
rules=(
  "hard${T}-iE${T}em dash${T}—"
  "hard${T}-iE${T}double hyphen as dash${T}[^[:space:]-] -- [^[:space:]-]"
  "hard${T}-iE${T}spaced en dash as pause${T}[^[:space:]] – [^[:space:]]"
  "hard${T}-iE${T}unicode arrow${T}→|←|↔|⇒|⇐|⇔|⟶|⟵|↑|↓"
  "hard${T}-iE${T}middle dot separator${T} · "
  "hard${T}-E${T}semicolon${T}[^;]{0,30};[^;]{0,30}"
  "hard${T}-iE${T}AI phrase${T}\\bdelv(e|es|ed|ing)\\b|\\btapestr(y|ies)\\b|\\bseamless(ly)?\\b|\\btestament to\\b|\\bload-bearing\\b|\\bgenuinely\\b|\\bhere('|’)s the thing\\b|\\bit('|’)s worth noting\\b|\\bgreat question\\b|\\bI hope this helps\\b|\\bin conclusion\\b|\\bperfect!"
  "warn${T}-iE${T}pitch-deck copy${T}\\bfrictionless\\b|\\bholistic\\b|\\bsupercharg(e|es|ed|ing)\\b|\\breimagin(e|es|ed|ing)\\b|\\bgame-chang(er|ing)\\b|\\bnext-gen(eration)?\\b|\\benterprise-grade\\b|\\bmove the needle\\b|\\bdo more with less\\b|\\bin today('|’)s (rapidly )?(evolving|changing|fast-paced)\\b|\\bthe future of [a-z]+ is (here|now)\\b|\\bNo [^.]{1,30}\\. No [^.]{1,30}\\. Just\\b"
  "warn${T}-iE${T}closing moral${T}\\bdepends (mainly|largely|strongly|primarily|heavily|chiefly) on\\b|hängt [^.]{0,60}(stark|vor allem|maßgeblich|wesentlich|hauptsächlich) davon ab|never (learned|learns|knew|knows|found out|finds out) why|erf(ährt|uhr) (es )?nie,? warum"
  "warn${T}-iE${T}aggregate-hides pivot${T}\\b(overall|pooled|aggregate|headline|average) (figure|number|result|value|mean|median)s? ((therefore|thus|however|also) )?(hides|masks|obscures|conceals)\\b|(Gesamtwert|Gesamtzahl|Mittelwert|Median)( [[:alnum:]]+)? verdeckt|\\bwas (uneven|not uniform) across\\b"
  "warn${T}-iE${T}colon reveal${T}\\b(the|a) (cause|reason|culprit|answer|problem|catch|difference) (is|was) [^.:]{1,40}:|\\b(Grund dafür|Die Ursache|Der Grund) (ist|war) [^.:]{1,50}:|\\b(found|finds|saw|sees) it: |, bis sie es [a-zäöü]+: "
  "warn${T}-iE${T}fact-and-so chain${T}, and [^.,;]+, so |, und [^.,;]+, (sodass|deshalb|daher) "
  "warn${T}-iE${T}sensory slot${T}smell(s|ed)? of [a-z]+( [a-z]+)? and |riecht(e)?( es)? nach [^.,]{1,25} und "
  "warn${T}-iE${T}default story image${T}found (a|its) (new|old) (sound|voice)|lights? (shrink|shrank|recede|receded|grow small|grew small|slide away|slid away)|Lichter [^.]{0,30}kleiner|like a spoon|wie ein Löffel|Metall auf Metall"
  "warn${T}-iE${T}form label${T}^\\*\\*(Title|Description|Titel|Beschreibung|Subject|Betreff):\\*\\*"
)
if (( fiction )); then
  rules+=(
    "warn${T}-iE${T}withheld knowledge${T}\\b(didn't|did not|never|doesn't|does not) (know|knew|learn|learned|learns|find out|found out|finds out)( it| this| that| why| what)?[.!]|\\bthis one (she|he|they) (didn't|did not) |(kannte|kennt|wusste|weiß|erfuhr|erfährt) (sie|er|es)? ?(nie|nicht)( davon| warum| es)?[.!]|Dieses? [[:alpha:]]+ kannte (sie|er) nicht"
    "warn${T}-iE${T}body-part familiarity${T}\\bkn(ew|ows?) [^.]{0,50}\\blike (the back of )?(her|his|their|my) (own )?[a-z]+|kannte [^.]{0,50}(so gut )?wie (ihr|sein|ihre|seine|ihren|seinen) (eigene[ns]? )?[[:alpha:]]+"
    "warn${T}-iE${T}resume number${T}\\b(was|is|turned) (twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)(-[a-z]+)?\\b|\\b[0-9]+ years old|\\bfor (twenty|thirty|forty|fifty|[a-z]+-[a-z]+|[0-9]+) years\\b|\\b(ist|war|wurde) [[:alpha:]]*(zwanzig|dreißig|vierzig|fünfzig|sechzig|siebzig|achtzig|neunzig)\\b|\\bseit [[:alpha:]]+ Jahren\\b"
  )
fi
if (( de )); then
  rules+=(
    "hard${T}-iE${T}AI phrase (de)${T}Tauchen Sie ein|In der heutigen Zeit|Zusammenfassend lässt sich sagen"
    "hard${T}-E${T}english curly quote (de)${T}”|’"
    "hard${T}-E${T}mismatched quotes (de)${T}„[^“”\"]*\"|\"[^„“\"]*“"
    "warn${T}-P${T}request without bitte${T}\\b(Könnten|Können|Würden) Sie\\b(?![^?]*\\bbitte\\b)[^?]*\\?"
    "warn${T}-E${T}Sie/sie clash${T}\\bSie [a-zäöü]+ sie\\b"
    "warn${T}-iE${T}calque${T}für Sie in Ordnung|passt (das )?für Sie|\\bverdeckt\\b|den [^.]{0,30} berichten \\[|macht Sinn"
    "warn${T}-iE${T}anglicism${T}\\bfinale[nmrs]?\\b"
    "warn${T}-iE${T}Nominalstil${T}zur Verfügung (steh|stell)|Das entspricht einer|zur Anwendung (komm|bring)|in Anspruch (nehm|genommen)|einen Beitrag (zu )?leisten"
  )
else
  rules+=(
    "hard${T}-iE${T}curly quote${T}“|”|‘|’|„|‚"
    "warn${T}-iE${T}email formula${T}^Unfortunately,|whether this (change |swap )?works for you|sorry for the (short|late) notice\\.?$"
  )
fi

# Blank out fenced code and strip inline code spans, keeping line numbers intact.
strip_code() {
  local line fence=0
  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line =~ ^[[:space:]]*(\`\`\`|~~~) ]]; then
      fence=$((1 - fence))
      echo
      continue
    fi
    if (( fence )); then
      echo
      continue
    fi
    while [[ $line =~ \`[^\`]*\` ]]; do
      line=${line/"${BASH_REMATCH[0]}"/}
    done
    printf '%s\n' "$line"
  done
}

# Paragraph-level warnings. A prose paragraph is not a list, heading, title,
# subject line, greeting or sign-off.
structure() {
  awk -v de="$de" -v fiction="$fiction" '
    function flush(   s, n, last, w) {
      if (para == "") return
      if (para !~ /^([-*+] |[0-9]+\. |#|\*\*[^*]+\*\*$|(Subject|Betreff|Title|Titel):)/ &&
          length(para) > 25 && para !~ /,$/) {
        prose++
        if (fiction && prose == 1) {
          split(para, fs, /[.?!]+( |$)/); fw = split(fs[1], fww, / +/)
          if (fw > 18) printf "%d\twarn: long first sentence (%d words)\n", start, fw
        }
        s = gsub(/[.?!]+( |$)/, "&", para)
        if (s <= 1) { one++; run++; if (run == 2) printf "%d\twarn: consecutive one-sentence paragraphs\n", start }
        else run = 0
        if (fiction) {
          m = split(para, ss, /[.?!]+( |$)/); r = 0
          for (k = 1; k <= m; k++) {
            if (ss[k] == "") continue
            if (ss[k] ~ /["„“”]/) { r = 0; continue }  # dialogue may be terse
            if (split(ss[k], ww, / +/) <= 8) { if (++r == 2) printf "%d\twarn: run of very short sentences: %s\n", start, ss[k-1] ". " ss[k] }
            else r = 0
          }
        }
        if (s >= 3) {
          long++
          n = split(para, parts, /[.?!]+( |$)/)
          last = parts[n] != "" ? parts[n] : parts[n - 1]
          if (split(last, w, / +/) < 8) short++
        }
      } else run = 0
      para = ""
    }
    { words += NF }
    fiction { lc = tolower($0); cmp += gsub(/(^|[^a-z])(like a|like an|like the|as if|as though)[^a-z]|(^|[^a-zäöü])(wie ein|wie eine|wie der|wie die|wie das|als ob|als wäre|als könnte|als hätte)[^a-zäöü]/, "&", lc) }
    de && /sodass/ { sodass += gsub(/sodass/, "&") }
    /^[[:space:]]*$/ { flush(); next }
    { if (para == "") { start = NR; para = $0 } else para = para " " $0 }
    END {
      flush()
      if (prose >= 4 && one >= 2 && one / prose > 0.3) printf "%d\twarn: one-sentence paragraphs: %d of %d\n", 1, one, prose
      if (long >= 2 && short / long > 0.5) printf "%d\twarn: short closing sentence in %d of %d paragraphs\n", 1, short, long
      if (cmp > 2) printf "%d\twarn: %d comparisons (like/as if, wie ein/als ob), at most 2\n", 1, cmp
      if (sodass > 1 && sodass * 150 > words) printf "%d\twarn: sodass %d times in %d words\n", 1, sodass, words
    }'
}

# Runs of 5+ words shared with the brief. Emails and URLs are dropped first.
brief_echo() {
  awk -v bf="$brief" '
    function toks(line, arr,   n, i, out, k) {
      line = tolower(line)
      gsub(/[^[:space:]]*(@|:\/\/)[^[:space:]]*/, " ", line)
      gsub(/[^[:alnum:]]+/, " ", line)
      return split(line, arr, " ")
    }
    BEGIN {
      while ((getline l < bf) > 0) { n = toks(l, a); for (i = 1; i <= n; i++) b[++nb] = a[i] }
      for (i = 1; i + 4 <= nb; i++) gram[b[i] " " b[i+1] " " b[i+2] " " b[i+3] " " b[i+4]] = 1
    }
    { n = toks($0, a); for (i = 1; i <= n; i++) { t[++nt] = a[i]; ln[nt] = NR } }
    END {
      for (i = 1; i + 4 <= nt; i++)
        if ((t[i] " " t[i+1] " " t[i+2] " " t[i+3] " " t[i+4]) in gram)
          for (j = i; j <= i + 4; j++) hit[j] = 1
      for (i = 1; i <= nt; i++) {
        if (!hit[i]) continue
        s = t[i]; first = ln[i]
        while (hit[i+1]) s = s " " t[++i]
        printf "%d\twarn: brief echo: %s\n", first, s
      }
    }'
}

status=0
for file in "$@"; do
  if [[ $file == - ]]; then
    text=$(strip_code)
  elif [[ -f $file && -r $file ]]; then
    text=$(strip_code <"$file")
  else
    echo "check-tells.sh: cannot read $file" >&2
    exit 2
  fi

  hits=$(
    for entry in "${rules[@]}"; do
      IFS=$'\t' read -r sev flags name regex <<<"$entry"
      tag=$name
      [[ $sev == warn ]] && tag="warn: $name"
      grep -noa "$flags" -- "$regex" <<<"$text" | while IFS= read -r hit; do
        printf '%s\t%s: %s: %s\n' "${hit%%:*}" "$file:${hit%%:*}" "$tag" "${hit#*:}"
      done
    done
    structure <<<"$text" | while IFS=$'\t' read -r n msg; do printf '%s\t%s: %s\n' "$n" "$file:$n" "$msg"; done
    if [[ -n $brief ]]; then
      brief_echo <<<"$text" | while IFS=$'\t' read -r n msg; do printf '%s\t%s: %s\n' "$n" "$file:$n" "$msg"; done
    fi
  )
  hits=$(sort -n -s -k1,1 <<<"$hits" | cut -f2- | sed '/^$/d')
  if [[ -n $hits ]]; then
    printf '%s\n' "$hits"
    grep -qv ': warn: ' <<<"$hits" && status=1
  fi
done
exit "$status"
