# github-auto-changelog
This repository contains the changelogs for each PR merge for all the github repos where this server link is added under webhook


# how it works

- This repo is a ruby server which runs a script. 
- This server is supposed to be up and server address should be added to the webhooks of the github repo for which you want to generate the changelog.
- Script fetches specfied tags from PR descriptions and generates changelog.
- Script then automatically pushes changelog script to a specified repo with specified credentails
- All the variables need to be specified in changelog.rb file
