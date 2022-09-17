#!/bin/bash
https://github.com/bormaxi8080/linkedin2md.git

#bash build.sh "/Volumes/Transcend/projects/linkedin2md/output"

if [ ${#@} -lt 1 ]; then
  echo "usage: $0 [BUILD PATH]"
  exit 1;
fi

BUILD_PATH=$1

TMP="./tmp"

echo "This is script for build markdown resume database parsed from LinkedIn and other resources in JSON format."
echo "Read README documentation for more information."
echo "Source folder: $BUILD_PATH"
echo ""

echo "Start database building..."
echo ""

# remember current path
CURRENT_PATH="$PWD"

# files counter
COUNTER=0;

# delete main .md database file
rm -rf "$BUILD_PATH/.profiles.md"

# remove database file
rm -rf "$BUILD_PATH/profiles.md"

BUILD_TEXT="# Profiles list:
"
echo "$BUILD_TEXT" > "$BUILD_PATH"/"profiles.md"

# main profiles loop
for profile_dir in $(find "$BUILD_PATH/resume" -depth 1 -type d)
do
  PROFILE_TEXT=""

  # shellcheck disable=SC2006
  base_name=`basename "$profile_dir"`
  echo "Processing profile: $base_name"

  if [ ! -f "$profile_dir"/"$base_name.resume.json" ]; then
      echo "Profile $profile_dir/$base_name.resume.json does not exists"
  else
    profile=$(<"$profile_dir/$base_name.resume.json")

      basics=$(echo "$profile" | jq ".basics")
        name=$(echo "$basics" | jq ".name")
        label=$(echo "$basics" | jq ".label")
        email=$(echo "$basics" | jq ".email")
        phone=$(echo "$basics" | jq ".phone")
        #url=$(echo "$basics" | jq ".url")
        #summary=$(echo "$basics" | jq ".summary")
        location=$(echo "$basics" | jq ".location")
          country_code=$(echo "$location" | jq ".countryCode")
        profiles=$(echo "$basics" | jq ".profiles")
          profiles_url=$(echo "$profiles" | jq -r ".[0,1].url")

      name="${name%\"}"
      name="${name#\"}"
      label="${label%\"}"
      label="${label#\"}"
      email="${email%\"}"
      email="${email#\"}"
      phone="${phone%\"}"
      phone="${phone#\"}"
      #url="${url%\"}"
      #url="${url#\"}"
      #summary="${summary%\"}"
      #summary="${summary#\"}"
      country_code="${country_code%\"}"
      country_code="${country_code#\"}"

      dt=$(date +"%d.%m.%Y")

    PROFILE_TEXT="### $name
[Summary]($base_name/$base_name.summary.md)  [MD]($base_name/$base_name.md)  [VCF]($base_name/$base_name.vcf)  [PDF]($base_name/$base_name.pdf)  [PDF original]($base_name/$base_name.original.pdf)  [JSON]($base_name/$base_name.resume.json)

$dt $country_code
$email $phone
$profiles_url

$label

----
"

    echo "$PROFILE_TEXT" >> "$BUILD_PATH"/"profiles.md"
  fi

  # shellcheck disable=SC2219
  let "COUNTER+=1";
done

#echo "$BUILD_TEXT" > "$BUILD_PATH"/"profiles.md"

echo "$COUNTER profiles processed"
echo "Done"
