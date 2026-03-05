
#############################################
# SFDX / SF CLI
#############################################

_exists sf || return 0

# --- org management (global, not project-specific) ---

# List all authenticated orgs
alias sfl="sf org list --all --verbose"

# Logout from orgs
# usage: sfd alias1 alias2 ...
sfd() {
    for ORG in $@; do
        sf org logout -o $ORG --no-prompt
    done
    sfl
}

# Auth to any org by domain
# usage: sfa foo              → https://foo.my.salesforce.com (alias: foo-prod)
#        sfa foo--bar         → https://foo--bar.sandbox.my.salesforce.com (alias: foo-bar)
#        sfa foo-dev-ed       → https://foo-dev-ed.develop.my.salesforce.com (alias: foo-dev-ed)
sfa() {
    domain=$(echo "${(L)1}" | sed -E 's|https://([^.]+).*|\1|')
    url="https://"
    alias="${domain//--/-}"

    if [[ $domain =~ '--' ]]; then
      url+="$domain.sandbox"
    elif [[ $domain =~ 'dev-ed' ]]; then
      url+="$domain.develop"
    else
      url+="$domain"
      alias="${domain}-prod"
    fi

    sf org login web --instance-url $url.my.salesforce.com --alias $alias --set-default
}

# Open org in browser
alias sfo="sf org open "
alias sfoo="sfo -o "
alias sfop="sfo --private "

# --- config helpers ---

# Set target org (local / global / dev hub)
alias sfct="sf config set target-org "
alias sfctg="sf config set --global target-org "
alias sfctdh="sf config set target-dev-hub "

# Show current config + target org
sfconf() {
    _green "Config"
    sf config list
    echo ""
    _green "Target Org"
    sf config get target-org
    echo ""
    _green "Target Dev Hub"
    sf config get target-dev-hub
}

sfwho() {
    sfconf
    echo ""
    sf org display --verbose 2> /dev/null
}

# --- npm run wrappers ---
# Most SF work now goes through per-project npm scripts.
# These are thin wrappers for the most common ones.

alias sfpush="npm run source:push"
alias sfpull="npm run source:pull"
alias sfdiff="npm run source:diff"
alias sfreset="npm run source:reset"

alias sft="npm run test"
alias sfta="npm run test:apex"

alias sfdata="npm run data"
alias sfdi="npm run data:import"
alias sfde="npm run data:export"

alias sfsync="npm run sync:update"

# --- quick references ---
# These are commands you run less often but want to remember.
#
# Auth:
#   npm run org:auth <domain> <alias>     Node.js auth wrapper
#   npm run org:open                      Open current target org
#   npm run org:list                      List orgs
#
# Source:
#   npm run source:compile                Compile all Apex (Tooling API)
#   npm run source:validate               Deploy dry-run
#
# Data:
#   npm run data:import:sim               Simulate import (no writes)
#   npm run data:export:verbose           Export with debug output
#
# Packaging (cgpm):
#   npm run package:patch                 Bump patch + build + push
#   npm run package:minor                 Bump minor + build + push
#   npm run package:promote               Promote latest version
#   npm run package:install:qa            Install latest to QA
#   npm run package:install:prod          Install latest to prod
#   npm run package:deploy:patch          Full pipeline: build → promote → install
#
# Promotion (bumble-bee-tpm):
#   npm run promote:dev                   Merge feature → dev
#   npm run promote:qa                    dev → qa
#   npm run promote:uat                   qa → uat
#   npm run promote:main                  uat → main
#
# Sync (template projects):
#   npm run sync                          Sync from template
#   npm run sync:preview                  Dry-run sync
#   npm run sync:modules                  Update git submodules
#   npm run sync:update                   Submodules + sync + npm install
#
# Scratch orgs:
#   sf org create scratch --definition-file config/project-scratch-def.json --alias my-scratch --duration-days 30 --set-default
#   sf org delete scratch --target-org my-scratch --no-prompt
#
# Permsets:
#   npm run access:assign:all             Assign Admin + User permsets
#   sf org assign permset --name Admin
#
# Debug:
#   npm run debug:toggle                  Toggle debug mode in target org
#
# SLDS:
#   npm run lint:slds                     Run SLDS linter
#   npm run lint:slds:fix                 Auto-fix SLDS issues
