function chrome-debug --description 'Launch Chrome with remote debugging on port 9222 (Profile 9)'
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
        --remote-debugging-port=9222 \
        --profile-directory='Profile 9' $argv
end
