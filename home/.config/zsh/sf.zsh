
#############################################
# SFDX
#############################################

if _exists sf; then
  alias sfl="sf org list --all"
  alias sfalias="sf alias set"

  function sfd {
    for ORG in $@
      do sf org logout -o $ORG --no-prompt
    done

    sfl
  }

  function sfa {
    if [[ ! -z $1 ]]; then

      if [[ $1 == 'p' ]]; then
        sf org login web --instance-url https://$2.my.salesforce.com
        elif [[ $1 == 's' ]]; then
        sf org login web --instance-url https://$2.sandbox.my.salesforce.com
      fi

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

