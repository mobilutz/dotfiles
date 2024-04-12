alias reload!='. ~/.zshrc'

alias cls='clear' # Good 'ol Clear Screen command

alias zshconfig="mate ~/.zshrc"
alias ohmyzsh="mate ~/.oh-my-zsh"
alias biggest="du -sk * | sort -rn | head -11"
alias rsp='bundle exec rails s -b 0.0.0.0 -p 3000 -u puma'
alias rs='bundle exec rails s -b 0.0.0.0'
alias rsu 'bundle exec unicorn -l 0.0.0.0:3000 -E development -c config/unicorn.rb'
alias rc='bundle exec rails c'
alias rdm='bundle exec rake db:migrate && bundle exec rake db:test:prepare'
alias rdr='bundle exec rake db:rollback && bundle exec rake db:test:prepare'
alias rdp='bundle exec rake db:populate && bundle exec rake db:test:prepare'
alias rgm='bundle exec rails generate migration'
alias rdtp='bundle exec rake db:test:prepare'
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
alias console='bundle exec rails c'
alias et='code'
alias gs='git status -sb'
alias addnw=!sh -c 'git diff -U0 -w --no-color "$@" | git apply --cached --ignore-whitespace --unidiff-zero -'
alias homebrew='brew'
alias ll='ls -ahl'
alias rubo="be rubocop -a \$(git status -s | ruby -ne 'print \$_.split(\" \").last, \" \"')"
alias listen="sudo lsof -i -P | grep -i \"listen\""
alias c-'code'
alias gcm='git commit --no-verify -m'

alias convert_heic='for f in *.HEIC; do sips -s format jpeg "${f}" --out "${f%.*}.jpg"; done'
