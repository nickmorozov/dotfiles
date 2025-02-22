
#############################################
# SFDX
#############################################

if _exists sf; then
  sfl() {
    sf org list --all --verbose
  }

  sfd() {
    for ORG in $@
      do sf org logout -o $ORG --no-prompt
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

  alias sfpdr="sf project retireve start "
  alias sfpds="sf project deploy start "
  alias sfpush="sfpds -d src -l NoTestRun "
  alias sfpushdir="sfpds -l NoTestRun -d "

  alias sfprs="sf project retrieve start "
  alias sfpull="sfprs -d src"

  alias sfstr="sf project reset tracking"

  sfst() {
    echo ""
    _green "Retrieve Status"
    sf project retrieve preview
    echo ""
    _green "Deploy Status"
    sf project deploy preview
  }

  sfsync() {
    sfpush && sfpull
  }

  alias sfct="sf config set target-org "
  alias sfctg="sf config set --global target-org "

  alias sfo="sf org open -o "
  alias sfoo="sfo -o "
  alias sfop="sfo --private "
  alias sfP="sfoo $PROD"
  alias sfU="sfoo $UAT"
  alias sfD="sfoo $DEV"
fi
