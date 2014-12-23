mkdir config
mkdir icons

if [! -e config/setting.json ]
then
  cat > config/setting.json << FIN
{
  "consumerKey"       : "",
  "consumerSecret"    : "",
  "accessToken"       : "",
  "accessTokenSecret" : ""
}
FIN
fi
