# Deletes obsolete gpg keys in the keyring
# Ref: https://superuser.com/a/1631427
alias gpg-delete-obsolete="gpg --list-keys --with-colons \
  | awk -F: '$1 == "pub" && ($2 == "e" || $2 == "r") { print $5 }' \
  | xargs gpg --batch --yes --delete-keys"
