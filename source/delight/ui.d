module delight.ui;
import gtk.CellRendererPixbuf,
       gtk.CellRendererText,
       gtkc.gdkpixbuftypes,
       gtk.ScrolledWindow,
       gtk.TreeViewColumn,       
       gtk.MainWindow,
       gtk.TextBuffer,
       gtk.TreeStore,
       gtk.ListStore,
       gtk.TextView,
       gtk.TreeIter,
       gtk.TreePath,
       gtk.TreeView,
       gtk.Button,
       gtk.Widget,
       gdk.Pixbuf,
       gtk.Label,
       gtk.Entry,
       gtk.Main,
       gtk.VBox,
       gtk.HBox;

import twitter4d;

struct TweetItem{
  string id,
         tweet;
  ubyte[] icon;
  bool key;
  enum status : bool{
    retweeted,
    favorited
  }
}

class delightUI{
  import std.net.curl,
         std.string,
         std.regex,
         std.stdio,
         std.file,
         std.conv,
         std.json;

  private Twitter4D t4d;
  private TreeStore store;
  private TreeView view;
  private ScrolledWindow swindow;
  private string[] opt;

  this(Twitter4D twitter4dInstance){
    t4d = twitter4dInstance;
  }

  this(Twitter4D twitter4dInstance, string[] optHash){
    this(twitter4dInstance);
    opt = optHash;
  }

  string getAccountName(){
    return getJsonData(parseJSON(t4d.request("GET", "account/verify_credentials.json", ["":""])), "screen_name");
  }

  void quit(){
    Main.quit;
    version(Posix){
      import core.thread,
             std.c.linux.linux;
      kill(getpid, SIGKILL);
    }
    // NEED : Add Windows
    //Need to more considering
  }

  bool tweet(string tweetString){
    if(tweetString.length == 0)
      return false;
    t4d.request("POST", "statuses/update.json", ["status" : tweetString]);
    return true;
  }

  void guiMain(){
    Main.init(opt);
    MainWindow mainWindow = new MainWindow("TimeLineView");
    VBox vbox = new VBox(false, 1);

    Label selectedLabel = new Label("");
    swindow = new ScrolledWindow;

    mainWindow.addOnDestroy(((Widget w) => quit));
    mainWindow.setDefaultSize(800, 400);

    store = new TreeStore([GType.STRING, Pixbuf.getType(), GType.STRING]);
    view = new TreeView(store);

    //Pick up the tweet when is is selected
    view.addOnRowActivated((TreePath path, TreeViewColumn column, TreeView view){
      auto selected = view.getSelectedIter;
      string selectedID    = selected.getValueString(0);
      string selectedTweet = selected.getValueString(2);
      selectedLabel.setText(selectedTweet);
    });

    TreeViewColumn idColumn  = new TreeViewColumn("1", new CellRendererText,   "text",   0);
    TreeViewColumn imgColumn = new TreeViewColumn("2", new CellRendererPixbuf, "pixbuf", 1);
    TreeViewColumn snColumn  = new TreeViewColumn("3", new CellRendererText,   "text",   2);

    idColumn.setMaxWidth(100);
    snColumn.setMaxWidth(300);

    view.appendColumn(idColumn);
    view.appendColumn(imgColumn);
    view.appendColumn(snColumn);

    swindow.addWithViewport(view);
    vbox.add(swindow);
    vbox.add(selectedLabel);
    mainWindow.add(vbox);

    mainWindow.showAll;
    Main.run;
  }

  void addElem(string id, string text, string iconURL){
    string iconPath = "icons/" ~ id ~ ".jpeg";

    TreeIter root = store.prepend(null);
    std.net.curl.download(iconURL, iconPath);
    Pixbuf pb = new Pixbuf(iconPath);

    store.setValue(root, 0, id);
    store.setValue(root, 1, pb);
    store.setValue(root, 2, text);
  }

  void streamEvent(JSONValue parsed){
    try{
      if("text" in parsed.object){
        string textData    = getJsonData(parsed, "text").removechars("\\");
        JSONValue userJson = parsed.object["user"];
        string name        = getJsonData(userJson, "name").removechars("\\");
        string screenName  = getJsonData(userJson, "screen_name").removechars("\\");
        string iconURL     = getJsonData(userJson, "profile_image_url").removechars("\\");
        addElem(screenName, textData, iconURL);
      }
    } catch (Exception ignored) {}
  }

  private{
    string getJsonData(JSONValue parsedJson, string key){
      return parsedJson.object[key].to!string.replace(regex("\"", "g") ,"");
    }
  }
}
