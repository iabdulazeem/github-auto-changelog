require 'sinatra'
require 'json'
require 'rubygems'
require 'git'

# Constants paths
LOCAL_CHANGELOG_GIT_PATH="./"
LOCAL_CHANGELOG_FILE_PATH="./destination/changelog.md"
# Git credentials
GIT_USERNAME="Abdul Azeem"
GIT_EMAIL="abdul.azeem@email.com"
# Others
PR_FIELDS_TO_CRAWL=["**TAGLINE", "**CATEGORY", "**CUSTOMERS_IMPACTED"]


#for testing
get '/rubytest' do
  {:res => "ruby script is up"}.to_json
end

post '/payload' do
  gitEventData = JSON.parse(request.body.read)
  if (gitEventData.key?("action") && gitEventData["action"]=="closed")
      puts "-----------------------"
      if(gitEventData.key?("pull_request") && gitEventData["pull_request"].key?("body"))
        isMerged=gitEventData["pull_request"]["merged"]
        mergedAt=gitEventData["pull_request"]["merged_at"]
        pRnumber=gitEventData["pull_request"]["number"]
        pRbody=gitEventData["pull_request"]["body"]
        puts "isMerged: #{isMerged}"
        puts "mergedAt: #{mergedAt}"
        puts "pRnumber: #{pRnumber}"
        puts "-----------------------"
        if isMerged
          pRAtributesArray=pRbody.split(/\r\n/)
          filteredAttributes = filterPRAttributes(pRAtributesArray)
          changeLog = "\n **PR#** #{pRnumber}; **Merged At:** #{mergedAt} ; #{filteredAttributes.join("; ")}"
          puts "changeLog: #{changeLog}"
          #write this changelog to changelog.md in same directory
          updateChangeLogFile(changeLog)
          #push changes to git
          syncWithGit()
        end
      end
      puts "-----------------------"
  end
end

def syncWithGit()
  puts "git sync start"
  g=Git.open(LOCAL_CHANGELOG_GIT_PATH)
  g.config('user.name', GIT_USERNAME)
  g.config('user.email', GIT_EMAIL)
  begin
    g.pull
    puts "pulled latest changes from remote"
  rescue
    puts "already uptodate"
  end
  begin
    g.add
    g.commit('new PR changelog')
    g.push
    puts "pushed chnagelog successfully"
  rescue
    puts "No new change log found"
  end
  puts "git sync end"
end

#open and write the changelog file
def updateChangeLogFile(newLine)
  puts "updating local changelog file"
  finalText = ""
  existingText=File.open(LOCAL_CHANGELOG_FILE_PATH).read
  finalText="#{existingText} \n #{newLine}"
  syncWithGit()
  File.write(LOCAL_CHANGELOG_FILE_PATH,finalText)
  File.foreach(LOCAL_CHANGELOG_FILE_PATH) { |text| puts text }
  puts "-----------------------"
end

# This function filters desired attributes from PRAtributesArray
def filterPRAttributes(allAttributesArray)
  filteredArray = []
  allAttributesArray.each { 
    |attributeStr| 
    PR_FIELDS_TO_CRAWL.each{
      |reqAtrributeStr|
      if attributeStr.include?reqAtrributeStr
        filteredArray.push(attributeStr)
      end
    }
  }
  #exception for **CATEGORY, because It's text comes on next line
  #you can remove this part if your PR description doesn't have such exception
  categoryText=allAttributesArray[allAttributesArray.find_index("**CATEGORY:**")+1]
  filteredArray[filteredArray.find_index("**CATEGORY:**")]="**CATEGORY:** #{categoryText}"
  return filteredArray
end

# Generate final string
def generateFinalString(attributesArray)
  finalString=""
  attributesArray.each{|attr| finalString="#{finalString}#{attr}; "}
  return finalString
end