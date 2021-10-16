on run (volumeName)
	tell application "Finder"
		log "1"
		tell disk (volumeName as string)
			log "2"
			open
			log "3"

			set theXOrigin to WINX
			set theYOrigin to WINY
			set theWidth to WINW
			set theHeight to WINH
			log "4"

			set theBottomRightX to (theXOrigin + theWidth)
			set theBottomRightY to (theYOrigin + theHeight)
			set dsStore to "\"" & "/Volumes/" & volumeName & "/" & ".DS_STORE\""
			log "5"

			tell container window
				log "6"
				set current view to icon view
				log "7"
				set toolbar visible to false
				log "8"
				set statusbar visible to false
				log "9"
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
				log "10"
				set statusbar visible to false
				log "11"
				REPOSITION_HIDDEN_FILES_CLAUSE
				log "12"
			end tell
			log "13"

			set opts to the icon view options of container window
			log "14"
			tell opts
				log "15"
				set icon size to ICON_SIZE
				log "16"
				set text size to TEXT_SIZE
				log "17"
				set arrangement to not arranged
				log "18"
			end tell
			log "19"
			BACKGROUND_CLAUSE
			log "20"

			-- Positioning
			POSITION_CLAUSE
			log "21"

			-- Hiding
			HIDING_CLAUSE
			log "22"

			-- Application and QL Link Clauses
			APPLICATION_CLAUSE
			log "23"
			QL_CLAUSE
			log "24"
			close
			log "25"
			open
			log "26"
			-- Force saving of the size
			delay 1
			log "27"

			tell container window
				log "28"
				set statusbar visible to false
				log "29"
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX - 10, theBottomRightY - 10}
				log "30"
			end tell
			log "31"
		end tell
		log "32"

		delay 1
		log "33"

		tell disk (volumeName as string)
			log "34"
			tell container window
				log "35"
				set statusbar visible to false
				log "36"
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
				log "37"
			end tell
			log "38"
		end tell
		log "39"

		--give the finder some time to write the .DS_Store file
		delay 3
		log "40"

		set waitTime to 0
		set ejectMe to false
		repeat while ejectMe is false
			log "41"
			delay 1
			log "42"
			set waitTime to waitTime + 1
			log "43"

			if (do shell script "[ -f " & dsStore & " ]; echo $?") = "0" then set ejectMe to true
			log "44"
		end repeat
		log "waited " & waitTime & " seconds for .DS_STORE to be created."
	end tell
	log "45"
end run
