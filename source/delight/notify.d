module delight.notify;

import twitter4d;
import std.net.curl,
       std.process,
       std.string,
       std.stdio,
       std.regex,
       std.file,
       std.conv,
       std.json;

class Notify{
  private{
    Twitter4D t4d;
    string iconBasePath;
    string userName;
    string defaultTime = "1500";
  }

  this(Twitter4D twitter4dInstance){
    iconBasePath = getcwd() ~ "/icons";

    t4d = twitter4dInstance;
    userName = getJsonData(parseJSON(t4d.request("GET", "account/verify_credentials.json", ["" : ""])), "screen_name");
  }

  void notify(JSONValue parsed){
    try{
      if("event" in parsed.object)
        execNotification(parseEvent(parsed));
      if("text" in parsed.object){//For retweet notify
        string textData = getJsonData(parsed, "text");
        if(match(textData, regex(r"@" ~ userName))){//For Reply
          JSONValue userJson = parsed.object["user"];
          string name       = getJsonData(userJson, "name");
          string screenName = getJsonData(userJson, "screen_name");
          string[string] message;

          if(match(textData, regex(r"^RT @" ~ userName))){
            message["event"]   = "retweet";
            message["icon"]    = getIconPath(userJson);
            message["urgency"] = "normal";
            message["wait"]    = defaultTime;
            message["title"]   = name ~ "(@" ~ screenName ~ ") retweet your tweet!";
            message["body"]    = getJsonData(parsed, "text").replace(regex(r"^ RT @" ~ screenName ~ r": \s"), "");
          } else {
            message["event"]   = "reply";
            message["icon"]    = getIconPath(userJson);
            message["urgency"] = "critical";
            message["wait"]    = defaultTime;
            message["title"]   = "Reply From " ~ name ~ "(@" ~ screenName ~ ")";
            message["body"]    = textData;
          }
          execNotification(message);
        }
      }
    } catch (Exception ignored) {}
  }

  private{
    string getJsonData(JSONValue parsedJson, string key){
      return parsedJson.object[key].to!string.replace(regex("\"", "g") ,"");
    }

    string[string] parseEvent(JSONValue parsedJson){
      string eventName     = getJsonData(parsedJson, "event");
      JSONValue targetJson = parsedJson.object["target"];
      JSONValue sourceJson = parsedJson.object["source"];
      string name          = getJsonData(sourceJson, "name");
      string screenName    = getJsonData(sourceJson, "screen_name");
      string[string] message = ["" : ""];

      switch(eventName){
        case "favorite":
          if(screenName == userName)
            goto default;
          message["event"]   = eventName;
          message["icon"]    = getIconPath(sourceJson);
          message["urgency"] = "normal";
          message["wait"]    = defaultTime;
          message["title"]   = name ~ "(@" ~ screenName ~ ") favorite your tweet!";
          message["body"]    = getJsonData(parsedJson.object["target_object"], "text");
          break;
        case "unfavorite":
          if(screenName == userName)
            goto default;
          message["event"]   = eventName;
          message["icon"]    = getIconPath(sourceJson);
          message["urgency"] = "critical";
          message["wait"]    = defaultTime;
          message["title"]   = name ~ "(@" ~ screenName ~ ") unfavorite your tweet";
          message["body"]    = getJsonData(parsedJson.object["target_object"], "text");
          break;
        case "follow":
          if(screenName == userName)
            goto default;
          message["event"]   = eventName;
          message["icon"]    = getIconPath(sourceJson);
          message["urgency"] = "normal";
          message["wait"]    = defaultTime;
          message["title"]   = "<span size=\"10500\">" ~ name ~ "(@" ~ screenName ~ ") follow you!" ~ "</span>";
          message["body"]    = "";
          break;
        default:
          break;
      }
      return message;
    }

    string getIconPath(JSONValue sourceJson){
      string iconUrl    = getJsonData(sourceJson, "profile_image_url_https").replace(regex(r"\\", "g"), "");
      string screenName = getJsonData(sourceJson, "screen_name");
      string iconPath;

      if(saveIconImage(iconUrl, screenName))
        iconPath = iconBasePath ~ "/" ~ screenName ~ ".jpeg";
      else
        iconPath = "NULL";
      return iconPath;
    }

    bool saveIconImage(string iconUrl, string screenName){
      string iconPath = iconBasePath ~ "/" ~ screenName ~ ".jpeg";
      writeln(iconUrl);
      download(iconUrl, iconPath);
      if(!exists(iconPath))
        return false;
      return true;
    }

    void execNotification(string[string] sendMessage){
      if(sendMessage == ["" : ""])
        return;
      writeln("[EVENT] => ", sendMessage["event"]);
      string notifyCommandString = "notify-send ";
      if(sendMessage["icon"] != "NULL")
        notifyCommandString ~= "-i " ~ sendMessage["icon"] ~ " ";
      notifyCommandString ~= "-u " ~ sendMessage["urgency"] ~ " ";
      notifyCommandString ~= "-t " ~ sendMessage["wait"] ~ " ";
      notifyCommandString ~= "\'" ~ sendMessage["title"] ~ "\'" ~ " ";
      notifyCommandString ~= "\'" ~ sendMessage["body"] ~ "\'";
      system(notifyCommandString);
    }
  }
}
