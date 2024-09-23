alias reload!='. ~/.zshrc'

alias cls='clear' # Good 'ol Clear Screen command
alias cat='bat'
alias ls='eza'
alias ll='ls -ahl'

alias zshconfig="code ~/.zshrc"
alias ohmyzsh="code ~/.oh-my-zsh"

alias biggest="du -sk * | sort -rn | head -11"

alias rsp='bundle exec rails s -b 0.0.0.0 -p 3000 -u puma'
alias rs='bundle exec rails s -b 0.0.0.0'
alias rsu='bundle exec unicorn -l 0.0.0.0:3000 -E development -c config/unicorn.rb'
alias rc='bundle exec rails c'
alias console='bundle exec rails c'
alias rdm='bundle exec rake db:migrate && bundle exec rake db:test:prepare'
alias rdr='bundle exec rake db:rollback && bundle exec rake db:test:prepare'
alias rdp='bundle exec rake db:populate && bundle exec rake db:test:prepare'
alias rgm='bundle exec rails generate migration'
alias rdtp='bundle exec rake db:test:prepare'
alias rubo="bundle exec rubocop -a \$(git status -s | ruby -ne 'print \$_.split(\" \").last, \" \"')"

alias hc='heroku run rails c'
alias hpg= 'heroku pg:psql'
alias hmon='heroku maintenance:on'
alias hmoff='heroku maintenance:off'
alias hpsql='heroku pg:psql'
alias hl='heroku logs -t'

alias be='bundle exec'
alias bi='bundle install'
alias bu='bundle update'

alias dce='docker-compose exec app'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dcbe='dce bundle exec'
alias dcstart='docker-compose start'
alias dcstop='docker-compose stop'
alias dcbi='dce bundle install'
alias dcrc='dcbe rails c'
alias dcbuild='docker-compose build'
alias dcrdm='dcbe rails db:migrate:with_data db:test:prepare'

alias et='code'
alias c='code'

alias homebrew='brew'

alias listen="sudo lsof -i -P | grep -i \"listen\""

alias convert_heic='for f in *.[hH][eE][iI][cC]; do sips -s format jpeg "${f}" --out "${f%.*}.jpg"; rm "${f}"; done'
alias exif_rename='for f in *.[jJ][pP]*[gG]; do jhead -n%Y-%m-%d_%H-%M-%S "${f}"; done'
alias mov_rename='for f in IMG_*.[mM][oOp][vV4]; do new_f="${f:4:4}-${f:8:2}-${f:10:2}_${f:13:2}-${f:15:2}-${f:17:2}.${f/*./}"; echo "\tRenaming $f  ->  ${new_f}"; mv $f $new_f; done'
alias convert_images='convert_heic; exif_rename; mov_rename'

function dockersize() {
  docker manifest inspect -v "$1" | jq -c 'if type == "array" then .[] else . end' |  jq -r '[ ( .Descriptor.platform | [ .os, .architecture, .variant, ."os.version" ] | del(..|nulls) | join("/") ), ( [ .SchemaV2Manifest.layers[].size ] | add ) ] | join(" ")' | numfmt --to iec --format '%.2f' --field 2 | column -t ;
}

function gitcombine() {
	if [ "$1" != "" ]
	then
		git rebase -i HEAD~$@
	else
		echo "call 'gitcombine' with one paramter"
		exit 1
	fi
}

# This add a current change into a past commit.
# The commits SHA needs to be passed as a second parameter.
#
# USAGE:   git-amend-to 12345
#
function git-amend-to() (
  # Stash, apply to past commit, and rebase the current branch on to of the result.
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  apply_to="$1"
  git stash
  git checkout "$apply_to"
  git stash pop
  git add -u
  git commit --amend --no-edit
  new_sha="$(git log --format="%H" -n 1)"
  git checkout "$current_branch"
  git rebase --onto "$new_sha" "$apply_to"
)
