#############################################
# SFDX / SF CLI
#############################################
_exists() {
    command -v $1 > /dev/null 2>&1
}

_green() {
    echo -e "\e[32m$@\e[0m"
}

if _exists sf; then
    sfl() {
        sf org list --all --verbose
    }

    sfd() {
        for ORG in $@; do
            sf org logout -o $ORG --no-prompt
        done

        sfl
    }

    sfa() {
        if [[ ! -z $1 ]]; then
            if [[ -z $2 ]]; then
                echo "Usage: sfa <instance-name> <alias>"
                return 1
            fi

            URL="https://"

            if [[ $1 =~ '--' ]]; then
                URL+="$1.sandbox"
                # sf org login web --instance-url https://$1.sandbox.my.salesforce.com --alias $2
            elif [[ $1 =~ 'dev-ed' ]]; then
                URL+="$1.develop"
                # sf org login web --instance-url https://$1.develop.my.salesforce.com --alias $2
            else
                URL+="$1"
                # sf org login web --instance-url https://$1.my.salesforce.com --alias $2
            fi

            sf org login web --instance-url $URL.my.salesforce.com --alias $2
        else
            sf org login web
        fi

        sfl
    }

    # --- project retrieve / deploy quick refs ---
    # preview retrieves metadata diff from target org
    # start actually pulls or pushes
    # --ignore-conflicts lets you deploy even if local != remote
    # usage examples / reminders
    #   sf project retrieve preview -o MyTestOrg1
    #   sf project retrieve start   -o MyTestOrg1
    #   sf project deploy preview   -o MyTestOrg1 --ignore-conflicts
    #   sf project deploy start     -o MyTestOrg1 --ignore-conflicts
    # other helpful built-in commands:
    #   sf alias list
    #   sf alias set my-scratch-org=test-sadbiytjsupn@example.com my-other-scratch-org=test-ss0xut7txzxf@example.com
    #   sf alias unset my-alias my-other-alias
    #   sf config get target-org
    #   sf config list
    #   sf config set --global target-org=my-scratch-org target-dev-hub=my-dev-hub
    #   sf config set target-dev-hub=corrao-group-prod
    #   sf config unset target-org api-version --global
    #
    #   sf org assign permset --name Admin
    #   sf org assign permset --name CGPM_Admin --on-behalf-of <non-admin-user>
    #
    # packaging workflow refs
    #
    #   sf apex run test --wait 999
    #   sf apex run test
    #   sf apex get test -i 707Ov00002fsvff
    #
    #   sf package create --name "CGPM" --path force-app --package-type Unlocked
    #   sf package version create --package "CGPM" -c --installation-key-bypass --wait 999
    #   sf package version promote --package "CGPM@0.1.0-4" -n
    #   sf package install --package "CGPM@0.1.0-1" --target-org corrao-group-uat --installation-key test1234 --wait 10 --publish-wait 10
    #   sf package install --package "CGPM@0.1.0-1" --target-org corrao-group-uat --wait 999 --publish-wait 999
    #
    #   sf package install --help
    #   sf data query --target-org $(sf config get target-dev-hub) --query "SELECT OrgKey, OrgName, OrgType, InstanceName, MetadataPackageId, MetadataPackageVersionId FROM PackageSubscriber WHERE MetadataPackageId = '033Qk000000ICkHIAW'" --result-format json
    #   sf package push-upgrade schedule --package 04tQk000000lsY1IAI --org-list 00DNq00000BxiWX

    # --- deploy / retrieve convenience aliases ---
    alias sfpds="sf project deploy start "
    alias sfpdp="sf project deploy preview "
    alias sfpush="sfpds -d src -l NoTestRun "
    alias sfpushdir="sfpds -l NoTestRun -d "

    alias sfprs="sf project retrieve start "
    alias sfprd="sf project retrieve preview "
    alias sfpull="sfprs -d src"

    alias sfstr="sf project reset tracking"

    sfst() {
        echo ""
        _green "Retrieve Status"
        sfprd
        echo ""
        _green "Deploy Status"
        sfpdp
    }

    sfsync() {
        sfpush && sfpull
    }

    # --- config helpers ---
    # set target org for JUST THIS PROJECT
    alias sfct="sf config set target-org "
    # set target org GLOBALLY
    alias sfctg="sf config set --global target-org "
    # set default dev hub for packaging in this project
    alias sfctdh="sf config set target-dev-hub "
    # inspect current config (local + global)
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

    # --- org helpers ---
    # open org by alias/username
    alias sfo="sf org open "
    # alias for convenience / muscle memory
    alias sfoo="sfo -o "
    alias sfop="sfo --private "
    alias sfP="sfoo $PROD"
    alias sfU="sfoo $UAT"
    alias sfD="sfoo $DEV"

    # who am i / what org am i aimed at?
    sfwho() {
        sfconf
        echo ""
        sf org display --verbose 2> /dev/null
    }

    # --- scratch org lifecycle ---
    # create a scratch org using a project-scratch-def, set it as default target, assign alias
    # usage: sfscratch config/project-scratch-def.json MyScratchAlias 7
    sfscratch() {
        ALIAS=$1
        DEF_FILE=${2:-"config/project-scratch-def.json"}
        DAYS=${3:-30}

        if [[ -z $ALIAS ]]; then
            echo "Usage: sfscratch <alias> [def-file] [days]"
            return 1
        fi

        sf org create scratch \
            --definition-file "$DEF_FILE" \
            --alias "$ALIAS" \
            --duration-days "$DAYS" \
            --set-default
        sf org list --all --verbose
    }

    alias sft="sf apex run test --wait 999 --result-format human"
    alias sftc="sft --code-coverage"

    # delete a scratch org by alias and clean up config target-org if it was pointing there
    # usage: sfscratchdel MyScratchAlias
    sfscratchdel() {
        if [[ -z $1 ]]; then
            echo "Usage: sfscratchdel <alias>"
            return 1
        fi

        sf org delete scratch --target-org "$1" --no-prompt
        sf org list --all --verbose
    }

    # --- packaging helpers ---
    # create (register) the unlocked package in the Dev Hub
    # usage: sfpkgcreate CGPM force-app Unlocked
    sfpkgcreate() {
        NAME=$1
        PATH=$2
        TYPE=$3

        if [[ -z $NAME || -z $PATH || -z $TYPE ]]; then
            echo "Usage: sfpkgcreate <name> <path> <Unlocked|Managed|ManagedBeta>"
            return 1
        fi

        sf package create \
            --name "$NAME" \
            --path "$PATH" \
            --package-type "$TYPE"
    }

    # build a new package version for deployment
    # usage: sfpkgver CGPM
    sfpkgver() {
        PKG=$1
        if [[ -z $PKG ]]; then
            echo "Usage: sfpkgver <packageNameOrAlias>"
            return 1
        fi

        sf package version create \
            --package "$PKG" \
            --installation-key-bypass \
            --wait 999
    }

    # install a package version into a target org
    # usage: sfpkginst 04tXXXX... MyTargetAlias
    # or:    sfpkginst CGPM@1.0.0-1 MyTargetAlias
    sfpkginst() {
        PKG_VERSION=$1
        TARGET_ORG=$2

        if [[ -z $PKG_VERSION || -z $TARGET_ORG ]]; then
            echo "Usage: sfpkginst <04t-or-alias@version> <targetOrgAlias>"
            return 1
        fi

        sf package install \
            --package "$PKG_VERSION" \
            --target-org "$TARGET_ORG" \
            --wait 999 \
            --publish-wait 999 \
            --no-prompt
    }

    # check status of a package install request
    # usage: sfpkginststatus 0HfXYZ... MyTargetAlias
    sfpkginststatus() {
        REQUEST_ID=$1
        TARGET_ORG=$2

        if [[ -z $REQUEST_ID || -z $TARGET_ORG ]]; then
            echo "Usage: sfpkginststatus <requestId> <targetOrgAlias>"
            return 1
        fi

        sf package install report \
            --request-id "$REQUEST_ID" \
            --target-org "$TARGET_ORG"
    }

fi