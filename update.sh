#!/bin/bash
#https://github.com/bormaxi8080/linkedin2md.git

#bash build.sh "/Volumes/Transcend/projects/linkedin2md/input"
# "/Volumes/Transcend/projects/linkedin2md/output"
# "/Volumes/Transcend/projects/linkedin2md/backup"
# 1

if [ ${#@} -lt 3 ]; then
    echo "usage: $0 [SOURCE PATH] [DESTINATION PATH] [BACKUP_PATH]"
    exit 1;
fi

SOURCE_PATH=$1
DESTINATION_PATH=$2
BACKUP_PATH=$3

REGENERATE=0
if [ "$4" ]
then
  if [ "$4" == 1 ]
  then
    REGENERATE=1
  else
    REGENERATE=0
  fi
fi

# temp path
TMP="./tmp"

# remember current path
CURRENT_PATH="$PWD"

echo "This is script for build candidates resume parsed from LinkedIn and other resources in JSON format."
echo "See README documentation for more information."
echo "Source folder: $SOURCE_PATH"
echo "Destination folder: $DESTINATION_PATH"
echo "Backup folder: $BACKUP_PATH"
echo ""

echo "Start resume building..."
echo ""

# remove trash
rm -rf "$SOURCE_PATH"/".DS_Store"
rm -rf "$TMP"/".DS_Store"

# files counter
COUNTER=0;

# markdown separator
SEPARATOR="----"

# summary profile text
PROFILE_TEXT=""

# JSON processing
for file in $(find "$SOURCE_PATH" -depth 1 -type f)
do
  # shellcheck disable=SC2006
  base_name=`basename "$file"`
  echo "Processing file: $base_name"

  # file extension
  extension="${file##*.}"
  # profile name
  profile_name="${base_name%.*}"

  # JSON
  if [ "$extension" = "json" ]
  then
    # shellcheck disable=SC2001
    profile_name=$(echo "$profile_name" | sed 's/.resume//g')
  fi

  # mk profile directory if not exists
  DIR=$DESTINATION_PATH"/resume/"$profile_name
  if [ ! -d "$DIR" ]; then
      # make profile directory if not exists
      mkdir "$DIR"
      mkdir "$DIR/artifacts"
  fi

  # JSON
  if [ "$extension" = "json" ]
  then
    ## TODO: check INVALID resume verification parameters

    # validate resume
    node HackMyResume/src/cli/index.js validate "$file" -d
    # analyze resume
    node HackMyResume/src/cli/index.js analyze "$file" --debug

    # build resumes in such formats
    #node HackMyResume/src/cli/index.js build "$file" TO "$TMP"/"${profile_name%.*}".all
    node HackMyResume/src/cli/index.js build "$file" TO "$TMP"/"${profile_name%.*}".md \
    "$TMP"/"${profile_name%.*}".pdf -d

    #rm -rf "$TMP"/"${profile_name%.*}.json"
    #rm -rf "$TMP"/"${profile_name%.*}.doc"
    rm -rf "$TMP"/"${profile_name%.*}.pdf.html"
    rm -rf "$TMP"/"modern-pdf.css"

    cp "$file" "$BACKUP_PATH"
    mv "$file" "$TMP"

    cd $TMP
    # shellcheck disable=SC2035
    cp * "$DIR"

    # shellcheck disable=SC2035
    rm -rf *.*
    # shellcheck disable=SC2103
    cd ..

    # write special profile summary file if it NOT exists only
    # as concept this is a minimalist script and data storage without profile exists and other checking
    if [ "$REGENERATE" == 1 ] || [[ "$REGENERATE" == 0 && ! -f "$DIR"/"$profile_name.summary.md" ]]; then
      # generate uniq profile id
      uuid=$(uuidgen)
      #echo "$uuid"

      profile=$(<"$DIR"/"$profile_name.resume.json")

      basics=$(echo "$profile" | jq ".basics")
        name=$(echo "$basics" | jq ".name")
        label=$(echo "$basics" | jq ".label")
        email=$(echo "$basics" | jq ".email")
        phone=$(echo "$basics" | jq ".phone")
        url=$(echo "$basics" | jq ".url")
        summary=$(echo "$basics" | jq ".summary")
        location=$(echo "$basics" | jq ".location")
          country_code=$(echo "$location" | jq ".countryCode")
        profiles=$(echo "$basics" | jq ".profiles")
          profiles_url=$(echo "$profiles" | jq -r ".[0,1].url")

          ## TODO: remove null values
          #profiles_url=$(sed -e 's/null//g')
          #echo "$profiles_url"

        #echo "$profiles_url"
        #echo "${#$profiles_url}"
        #length=$(echo -n "$profiles_url" | wc -m)
        #echo "$length"

        name="${name%\"}"
        name="${name#\"}"
        label="${label%\"}"
        label="${label#\"}"
        email="${email%\"}"
        email="${email#\"}"
        phone="${phone%\"}"
        phone="${phone#\"}"
        url="${url%\"}"
        url="${url#\"}"
        summary="${summary%\"}"
        summary="${summary#\"}"
        country_code="${country_code%\"}"
        country_code="${country_code#\"}"

      ## TODO: do not create empty values
      PROFILE_TEXT="# $name\n
$label\n
Profile ID: $uuid
Location: $country_code
Resume Links: [MD]($profile_name.md)  [VCF]($profile_name.vcf)  [PDF]($profile_name.pdf)  [PDF original]($profile_name.original.pdf)  [JSON]($profile_name.resume.json)\n
Profiles:
$profiles_url\n
Email: <a href='mailto:$email'>$email</a>
Phone: $phone
Url: $url\n
Summary:
$summary\n
### Additional information:\n$SEPARATOR\n
Place additional profile information here!\n\n$SEPARATOR
### Links:
[Contacts in VCF]($profile_name.vcf)
[Resume in Markdown]($profile_name.md)
[Original PDF]($profile_name.original.pdf)
[Generated PDF]($profile_name.pdf)
[Source JSON]($profile_name.resume.json)\n
[Profiles List](/profiles.md)"
      echo -e "$PROFILE_TEXT" > "$DIR"/"$profile_name.summary.md"

      dt=$(date +"%d.%m.%Y")

      PROFILE_TEXT="### $name
[Summary]($profile_name/$profile_name.summary.md)  [MD]($profile_name/$profile_name.md)  [VCF]($profile_name/$profile_name.vcf)  [PDF]($profile_name/$profile_name.pdf)  [PDF original]($profile_name/$profile_name.original.pdf)  [JSON]($profile_name/$profile_name.resume.json)

$dt $country_code
$email $phone
$profiles_url

$label

----
"
     echo "$PROFILE_TEXT" >> "$DESTINATION_PATH"/"profiles.md"

    fi
  fi

  # PDF (original)
  if [ "$extension" = "pdf" ]
  then
    rm -rf "$DIR"/"$profile_name.original.$extension"
    cp "$file" "$DIR"/"$profile_name.original.$extension"
    cp "$file" "$BACKUP_PATH"/"$profile_name.original.$extension"
    rm -rf "$file"
  fi

  # VCF
  if [ "$extension" = "vcf" ]
  then
    rm -rf "$DIR"/"$base_name"
    cp "$file" "$BACKUP_PATH"
    mv "$file" "$DIR"
  fi

  # shellcheck disable=SC2219
  let "COUNTER+=1";
  echo ""
done

echo "Processed $COUNTER files"
echo "Done"
