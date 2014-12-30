module delight.main;
import twitter4d;
import delight.notify,
       delight.ui;
import std.stdio,
       std.regex,
       std.json,
       std.file,
       std.conv;
import core.thread;

class Debug{
  bool main;
  bool ui;
  bool notify;
}

class Delight{
  private Twitter4D t4d;
  private Notify notify;
  private delightUI ui;
  private core.thread.Thread uiThread;
  private Debug debugFlag; 
  
  this(){
    debugFlag = new Debug; 
    string jsonString = readSettingFile;
    auto parsed = parseJSON(jsonString);
  
    t4d = new Twitter4D([
      "consumerKey"       : getJsonData(parsed, "consumerKey"),
      "consumerSecret"    : getJsonData(parsed, "consumerSecret"),
      "accessToken"       : getJsonData(parsed, "accessToken"),
      "accessTokenSecret" : getJsonData(parsed, "accessTokenSecret")]);
    
    notify = new Notify(t4d);
    ui     = new delightUI(t4d);
    uiThread = new core.thread.Thread(&ui.guiMain);
    uiThread.start;
    
    streamService;
  }
  
  private{
    void streamService(){
      foreach(line; t4d.stream){
        if(match(line.to!string, regex(r"\{.*\}"))){
          auto parsed = parseJSON(line.to!string);
          //ui.streamEvent(parsed);
          //notify.notify(parsed);
          new core.thread.Thread(() => ui.streamEvent(parsed)).start;
          new core.thread.Thread(() => notify.notify(parsed)).start;
        }
        
      }
    }
    
    string readSettingFile(){
      string settingFilePath = "config/setting.json";
      if(!exists(settingFilePath))
        throw new Error("Please create file of setting.json and configure your consumer & access tokens");
      
      auto file = File(settingFilePath, "r");
      string buf;
      
      foreach(line; file.byLine)
        buf = buf ~ cast(string)line;
        
      return buf;
    }
 
    string getJsonData(JSONValue parsedJson, string key){
      return parsedJson.object[key].to!string.replace(regex("\"", "g") ,"");
    }   
  }
}