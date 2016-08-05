#!/bin/sh

  increment=""
  newVersion=""
  currentVersion=$(git describe --abbrev=0 --tags)
  podspecFilename=""
  podSpecRepo=""


# Verify parameters
  if [ $# -lt 2 ]
  then
    echo " "
    echo "*** ERROR:  version increment and pod spec repo name must be supplied as parameters ***"
    echo "*** Example:  ./script_name 0.0.1 masterspecs ***"
    echo "*** Pod spec repo can be added by:  pod spec repo add <repo name> <repo url> ***"
    echo " "
    echo "Optional:  can add git commit comment as 3rd parameter"
    echo "Example:  ./script_name 0.0.1 masterspects \"commit comment\""
    echo " "
    exit 1
  fi

  if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
  then
    increment="$1"
  else
    echo " "
    echo "*** Error:  Version increment should be in the format X.X.X where X is an integer ***"
    echo " "
    exit 1
  fi

  if [ ! -z "$2" ]
  then
    podSpecRepo="$2"
  fi


  echo " "
  echo "current version: ""$currentVersion"

# Extract the Podspec Filename from the current directory
  for filename in *
  do
    rootname="${filename%.*}"
    extension="${filename##*.}"
  
    if [ "$extension" = "podspec" ]
    then
      podspecFilename="$rootname.$extension"
      echo "filename: $podspecFilename"
    fi
  done

  if [ "$podspecFilename" = "" ]
  then
    echo " "
    echo "*** ERROR: Script aborted:  *.podspec file not found. ***"
    echo " "
    exit 1
  fi

# Increment Version Number
  read major minor build <<< $( echo ${currentVersion} | awk -F"." '{print $1" "$2" "$3}' )
  read newMajor newMinor newBuild <<< $( echo ${increment} | awk -F"." '{print $1" "$2" "$3}' )

  if [ "$newMajor" -gt "0" ]
  then
    major=$((major+newMajor))
    minor=0
    build=0
  elif [ "$newMinor" -gt "0" ]
  then
    minor=$((minor+newMinor))
    build=0
  elif [ "$newBuild" -gt "0" ]
  then
    build=$((build+newBuild))
  fi

  echo "new version:  $major.$minor.$build"
  sed -i "" -e  "1,/s.version.*/s/s.version.*/s.version = \'$major.$minor.$build\'/" "$podspecFilename"
  
# Commit changes to Git
  commitComment="updating and tagging pod to $major.$minor.$build"
  if [ ! -z "$3" ]
  then
    commitComment="$commitComment - $3"
  fi

  echo ' ~~~ commiting and pushing changes to git with comment: $commitComment  ~~~ '
  echo " "
  git add .
  git commit -m "$commitComment"
  $(git tag "$major"."$minor"."$build")

# Validate Podspec
  echo " "
  echo ' ~~~ checking podspec ~~~ '
  echo " "
  read lintVomit <<< $(pod lib lint)
  
  grep "ERROR" $lintVomit
  if [ $? -eq 0 ]
  then
    echo " "
    echo "didn't work, will exit"
    exit 1
  fi

#   if [ $? -ne 0 ]
#   then
#     echo "*** ERROR: podspec did not pass vaidation."
#     echo "if your podspec has public/private dependencies, this may be expected"
#     read -p "Press any key to continue; ctrl+c to exit"
#   fi

# # Push to Git
#   git push origin master --tags

# # Push the Podspec
#   echo " "
#   echo ' ~~~ pushing podspec to spec repo ~~~ '
#   echo " "
#   echo $(pod repo push --allow-warnings "$podSpecRepo" "$podspecFilename")
#   echo " "
  echo 'Done'
  echo " "
  exit 0

