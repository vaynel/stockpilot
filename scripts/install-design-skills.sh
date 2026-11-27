#!/usr/bin/env bash
# Restore the skill revisions used to design StockPilot.
set -euo pipefail

skill_root="${CODEX_HOME:-$HOME/.codex}/skills"
installer="$skill_root/.system/skill-installer/scripts/install-skill-from-github.py"
destination="${1:-$skill_root}"

install_skill() {
    local name="$1" repo="$2" revision="$3" path="$4"
    if [[ -f "$destination/$name/SKILL.md" ]]; then
        printf 'Already present: %s\n' "$name"
        return
    fi
    python3 "$installer" --repo "$repo" --ref "$revision" --path "$path" \
        --name "$name" --dest "$destination" --method download
}

pstack_revision=eb4db2b55b2b7dec3d9282754cddf0a56bf4ff10
for skill in technical-writing unslop architect how arena; do
    install_skill "pstack-$skill" cursor/plugins "$pstack_revision" "pstack/skills/$skill"
done

agents_revision=c96b5f6552dba32e4492307493ee613581430715
install_skill api-design-principles wshobson/agents "$agents_revision" plugins/backend-development/skills/api-design-principles
install_skill postgresql-table-design wshobson/agents "$agents_revision" plugins/database-design/skills/postgresql-table-design
install_skill incident-runbook-templates wshobson/agents "$agents_revision" plugins/incident-response/skills/incident-runbook-templates
install_skill wicked-garden-product-acceptance-criteria mikeparcewski/wicked-garden f96ec1981b8d96345a36e88ffac73630a05d4e3c skills/product/acceptance-criteria
install_skill interface-design BenjaminWaye/codex-interface-design 2ca75228e11b0100f6c908c4e60e7e6390940df4 .
install_skill wireframe paperclipai/paperclip dadbc495b3cbdc171fddc40d09aafcc3e9206305 packages/skills-catalog/catalog/bundled/product/wireframe
install_skill playwright openai/skills 49f948faa9258a0c61caceaf225e179651397431 skills/.curated/playwright
