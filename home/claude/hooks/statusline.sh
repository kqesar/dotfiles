#!/usr/bin/env bash
# Status line Claude Code : modèle, effort, ultracode, dossier, branche git, contexte, quotas 5 h et hebdo.
# Champs lus sur stdin : https://code.claude.com/docs/en/statusline
input=$(cat)

IFS=$'\t' read -r model effort dir ctx five five_reset week week_reset < <(jq -r '[
  .model.display_name // "?",
  .effort.level // "",
  .workspace.current_dir // .cwd // "",
  (.context_window.used_percentage // "" | tostring),
  (.rate_limits.five_hour.used_percentage // "" | tostring),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.used_percentage // "" | tostring),
  (.rate_limits.seven_day.resets_at // "" | tostring)
] | @tsv' <<<"$input")

# Couleur selon le pourcentage consommé : vert < 50, jaune < 80, rouge au-delà.
color() {
  local p=${1%.*}
  if ((p >= 80)); then printf '\e[31m'; elif ((p >= 50)); then printf '\e[33m'; else printf '\e[32m'; fi
}

# Temps restant avant une remise à zéro (epoch en secondes) : « 2h13 », « 3j04h » ou « 12min ».
until_reset() {
  local s=$(($1 - $(date +%s)))
  ((s < 0)) && s=0
  if ((s >= 86400)); then printf '%dj%02dh' $((s / 86400)) $((s % 86400 / 3600))
  elif ((s >= 3600)); then printf '%dh%02d' $((s / 3600)) $((s % 3600 / 60))
  else printf '%dmin' $((s / 60)); fi
}

out="\e[1m${model}\e[0m"
[[ -n $effort ]] && out+=" \e[2m${effort}\e[0m"

# Ultracode n'est pas dans le JSON de la status line : on lit la clé `ultracode` des settings
# (le dernier fichier qui la définit l'emporte). Un `/effort ultracode` de session reste invisible.
ultra=false
for f in "$HOME/.claude/settings.json" "$dir/.claude/settings.json" "$dir/.claude/settings.local.json"; do
  v=$(jq -r 'if has("ultracode") then .ultracode else empty end' "$f" 2>/dev/null)
  [[ -n $v ]] && ultra=$v
done
[[ $ultra == true ]] && out+=" \e[36multracode\e[0m"

out+="  ${dir##*/}"

branch=$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null)
[[ -n $branch ]] && out+="  \e[35m⎇ ${branch}\e[0m"

[[ -n $ctx ]] && out+="  ctx $(color "$ctx")${ctx%.*}%\e[0m"

if [[ -n $five ]]; then
  out+="  5h $(color "$five")${five%.*}%\e[0m"
  [[ -n $five_reset ]] && out+=" ↻ $(until_reset "$five_reset")"
fi
if [[ -n $week ]]; then
  out+="  7j $(color "$week")${week%.*}%\e[0m"
  [[ -n $week_reset ]] && out+=" ↻ $(until_reset "$week_reset")"
fi

printf '%b\n' "$out"
