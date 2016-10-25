#!/usr/bin/env tclsh
proc createFile { filename } {
    # This procedures creates a new file that does not exists
    # It accpets one argument
    set fileToCreate [open ${filename} w]
    close $fileToCreate
    # if filename is  a file return file name or throw an error
    if {[file isfile ${filename} ]} {
	return ${filename}
    } else {
	error "Cannot create file ${filename}"
    }
}

proc watchFile { filename outFile args } {
    # This procedure watches for changes in a file
    # Save the size of the file 
    set fileSize [file size $filename]
    # Catch any error and output it out to the user
    catch { exec traceur $filename --out $outFile } err
    puts $err
    # run this forever
    while {1} {
	# check if the fileSize variable does not equal to the current file size of the file
	if { $fileSize != [file size $filename] } {
	    # if true run this block of code
	    puts ">>>> changes detected in $filename"
	    puts ">>>> $filename >> $outFile"
	    catch {exec traceur $filename --out $outFile } err
	    puts $err
	    # overwrite the fileSize variable with the current size of the filename
	    set fileSize [file size $filename]
	}
    }
}

for {set i 0} {$i<=$argc} {incr i} {
    set cmdVal [lindex $argv $i]
    switch -glob -- $cmdVal {
	"--file" {
	    # jump to the next arguemtn which is the argument passed to --file flag 
	    set fileName [lindex $argv [expr {$i+1}]]
	    if { [file isfile $fileName ]} {
		# if the file exists do nothing
	    } else {
		# Calling the createFile procedure if hte file does not exists
		puts "Cannot find file $fileName"
		puts "Creating file $fileName"
		set filename [createFile $fileName]
	    }
	}
	"--out" {
	    # Jump to the next arguement passed to the --outflag
	    set outFile [lindex $argv [expr {$i+1}]]
	    # if the fileName variable is false
	    # checking if truly the --file flag is called before the --out flag
	    if {![info exists fileName] } {
		set result [lsearch $argv "--file" ]
		if { $result != -1 } {
		    # file flag was called but called after the --out flag
		    puts "Execute --file flag before the out flag"
		    exit
		} else {
		    # --file flag was not called at all
		    puts "--file flag not found"
		    exit
		}
	    }
	    
	    if { $outFile == "" } {
		# if the user does not specify an outfile set outfile to the arguement passed to the --file flag
		# and then create fileName
		set outFile $fileName
		createFile $outFile
	    }
	    
	    if { [file isfile $outFile] } {
		# If outFile is in the same directory as fileName , fileName will be overwritten
		# Throw an error
		error "This will overwrite the file been watched"
	    } else {
		# Watch for changes in teh File by calling the watchFile procedure ( function )
		puts ">>>>> Watching $filename <<<<<<< "
		watchFile $fileName $outFile
	    }
	}
	[A-Za-z0-9/]*:[A-Za-z0-9/]* {  ; # match only values separated with just a : e.g abcd:efgh
	    
	    set folders [split $cmdVal :] ; #split the argument with : to create a list of the infile and outfile
	    set folderToWatch [lindex $folders 0] ; # the first index of the list is the foldertowatch
	    set folderToSaveChanges [lindex $folders 1] ; # the second index of the list is the folder to save changes

	    if { ! [ file isdirectory $folderToWatch ] } { ; # if the folder to watch does not exists create it
		puts "$folderToWatch does not exists"
		puts "Creating $folderToWatch"
		file mkdir $folderToWatch
	    }

	    if { ! [file isdirectory $folderToSaveChanges] } { ; # if the folder to save changes does not exists create it
		puts "$folderToSaveChanges does not exists"
		puts "Creating $folderToSaveChanges"
		file mkdir $folderToSaveChanges
	    }
	    # run forever
	    while {1} {
		set filesToWatch [glob -nocomplain $folderToWatch/*.js] ; # locate all .js file in the current directory
		if {![catch {glob $folderToWatch/*.js} ]} { ; # if glob does not throw any error
		    foreach files $filesToWatch {
			if { [catch {exec traceur $files \
					 --out ${folderToSaveChanges}/[file tail $files]} err ] } {
			    puts $err ; #catch any error while transpiling any file and output it
			} else {
			    # if the file transpiled successfully , save the size of the file and the file into
			    # fileArr array 
			    puts "\n\n>>>> Watching $files <<<<"
			    puts ">>>> $files >> ${folderToSaveChanges}/[file tail $files]<<<<\n"
			    set fileArr($files,"size") "[file size $files] $files"
			}
		    }
		}
		if {![catch {glob $folderToWatch/*.js} ]} { ; # A kind of repition to fix a bug
		    while {1} {
			foreach checkNewfiles [glob $folderToWatch/*.js] {
			    set result [lsearch $filesToWatch $checkNewfiles] ;#check if checkNewfiles is in filesToWatch
			    if { $result <= -1 } {
				# if checkNewfiles is not in result
				# start watching checkNewfiles
				puts "\n\n>>>> Detected new file $checkNewfiles <<<<"
				puts ">>>> Watching $checkNewfiles <<<<"
				
				if { [catch {exec traceur $checkNewfiles \
						 --out ${folderToSaveChanges}/[file tail $checkNewfiles]} err ] } {
				    puts $err
				} else {
				    puts "\n\n>>>> changes detected in [lindex $fileArr($qqq) 1] <<<<"
				    puts ">>>> $checkNewfiles >> ${folderToSaveChanges}/[file tail $checkNewfiles]<<<<"
				}
				set fileArr($checkNewfiles,"size") "[file size $checkNewfiles] $checkNewfiles"
				set filesToWatch [linsert $filesToWatch end $checkNewfiles]
			    } else {
				foreach qqq [array names fileArr] { ; # if result is not -1
				    set size [lindex $fileArr($qqq) 0] ; # get the first list element of fileArr array
				    # which contains the size of the file
				    # the catch statement inside the if block of code is to remove any deleted file from
				    # the fileArry and from the filesToWatch list
				    if { [catch {
					if { $size != [file size [lindex $fileArr($qqq) 1 ] ] } {
					    puts "[lindex $fileArr($qqq) 1] size has changed"
					
					    if { [catch {exec traceur [lindex $fileArr($qqq) 1] --out ${folderToSaveChanges}/[file tail [lindex $fileArr($qqq) 1]]} err]} {
					    
						puts $err
					    
					    } else {
						puts "\n\n>>>> changes detected in [lindex $fileArr($qqq) 1] <<<<"
						puts ">>>> [lindex $fileArr($qqq) 1] >> ${folderToSaveChanges}/[file tail [lindex $fileArr($qqq) 1]]"
					    }
					    set fileArr($qqq) "[file size [lindex $fileArr($qqq) 1]] [lindex $fileArr($qqq) 1]"					

					} ;#end of inner if
				    } err] } {
					puts "\n\n>>> [lindex $fileArr($qqq) 1] has been deleted <<<"
					set index [lsearch $filesToWatch [lindex $fileArr($qqq) 1] ]
					set filesToWatch [lreplace $filesToWatch 2 2]
					unset fileArr($qqq)
				    }
				    
				}
			    }
			}
		    } ; #end of if statement
		}
		after 3000
	    }
	}
	default {
	}
    } 
}
