
#############################################
# SFDX
#############################################

if _exists sf; then
  alias sfl="sf org list --all --verbose"

  alias sfalias="sf alias set"

  function sfd {
    for ORG in $@
      do sf org logout -o $ORG --no-prompt
    done

    sfl
  }

  function sfa {
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

  alias sfct="sf config set target-org "
  alias sfctg="sf config set --global target-org "

  alias sfo="sf org open "
  alias sfoo="sfo -o "
  alias sfop="sfo --private "
  alias sfP="sfoo $PROD"
  alias sfU="sfoo $UAT"
  alias sfD="sfoo $DEV"
fi

