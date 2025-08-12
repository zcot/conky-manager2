/*
 * Main.vala
 *
 * Copyright 2013 Tony George <teejee@teejee-pc>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using GLib;
using Gtk;
using Gee;
using Json;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public Main App;
public const string AppName = "Conky Manager";
public const string AppShortName = "conky-manager2";
public const string AppVersion = "2.73";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejeetech@gmail.com";
public const string AppAuthorEmail2 = "zcotcaudle@gmail.com";

const string GETTEXT_PACKAGE = "conky-manager2";
const string LOCALE_DIR = "/usr/share/locale";

extern void exit(int exit_code);

public class Main : GLib.Object {

	public string app_path = "";
	public string share_folder = "";
	public string data_dir = "";
	public string app_conf_path = "";
	public string desktop = "gnome";

	public Gee.ArrayList<string> search_folders;
	public Gee.ArrayList<ConkyRC> conkyrc_list;
	public Gee.ArrayList<ConkyTheme> conkytheme_list;

	public bool is_aborted;
	public string last_cmd;

	public int startup_delay = 20;
	public bool capture_background = false;
	public bool generate_png = true;
	//public int selected_widget_index = 0;
	public bool show_preview = true;
	public bool show_list = true;
	public bool show_active = false;
	public int pane_position = 300;
	public int window_width = 600;
	public int window_height = 500;

	//public string[] bg_scaling = {"center","fill","max","scale","tile"};
	public string[] bg_scaling = {"none","centered","tiled","stretched","scaled","zoomed"};
	public string[] bg_scaling_gnome = {"stretched","centered","tiled","stretched","scaled","zoomed"};
	public string[] bg_scaling_xfce = {"0","1","2","3","4","5"};
	public string[] bg_scaling_lxde = {"","center","tile","stretch","fit","crop"};

    public static int main(string[] args) {

		//set locale
		Intl.setlocale(GLib.LocaleCategory.MESSAGES, "");
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);

		//init GTK
		Gtk.init (ref args);

		//init TMP
		init_tmp();

		//init app
		App = new Main(args);

		//show window
		var window = new MainWindow();
		//quit app when window is closed
		window.destroy.connect(()=>{
			App.exit_app();
			Gtk.main_quit();
		});
		//save window size when closed
		window.delete_event.connect((event)=>{
			window.get_size(out App.window_width,out App.window_height);
			return false;
		});
		window.show_all();

		//run main loop
	    Gtk.main();

        return 0;
    }

    public Main(string[] args) {
		string home = Environment.get_home_dir();
		app_path = (File.new_for_path (args[0])).get_parent().get_path ();
		share_folder = "/usr/share";
		data_dir = home + "/.conky";
		app_conf_path = home + "/.config/conky-manager2.json";
		search_folders = new Gee.ArrayList<string>();

		conkyrc_list = new Gee.ArrayList<ConkyRC>();
		conkytheme_list = new Gee.ArrayList<ConkyTheme>();

		//check dependencies ---------------------

		string message;
		if (!check_dependencies(out message)){
			string title = _("Missing Dependencies");
			gtk_messagebox(title, message, null, true);
			exit(0);
		}

		//get desktop ---------------
		desktop = get_desktop_name().down();
		log_msg("Desktop: %s".printf(desktop));

		//install new theme packs and fonts ---------------

		init_directories();
		init_theme_packs();

		load_app_config();
	}

	public bool check_dependencies(out string msg){
		msg = "";

		string[] dependencies = { "conky", "rsync","killall","cp","rm","touch","7za","import" };

		string path;
		foreach(string cmd_tool in dependencies){
			path = get_cmd_path (cmd_tool);
			if ((path == null) || (path.length == 0)){
				msg += " * " + cmd_tool + "\n";
			}
		}

		if (msg.length > 0){
			msg = _("Commands listed below are not available") + ":\n\n" + msg + "\n";
			msg += _("Please install required packages and try running it again");
			log_error(msg);
			return false;
		}
		else{
			return true;
		}
	}

	public void save_app_config(){
		var config = new Json.Object();
		
		string home = Environment.get_home_dir();

		config.set_string_member("capture_background", capture_background.to_string());
		config.set_string_member("generate_png", generate_png.to_string());
		config.set_string_member("show_preview", show_preview.to_string());
		config.set_string_member("show_list", show_list.to_string());
		config.set_string_member("pane_position", pane_position.to_string());
		config.set_string_member("window_width", window_width.to_string());
		config.set_string_member("window_height", window_height.to_string());
		config.set_string_member("startup_delay", startup_delay.to_string());

		Json.Array arr = new Json.Array();
		foreach(string path in search_folders){
			if (path != data_dir){
				arr.add_string_element(path.replace(home,"~"));
			}
		}
		config.set_array_member("search-locations",arr);

		var json = new Json.Generator();
		json.pretty = true;
		json.indent = 2;
		var node = new Json.Node(NodeType.OBJECT);
		node.set_object(config);
		json.set_root(node);

		try{
			json.to_file(this.app_conf_path);
		} catch (Error e) {
	        log_error (e.message);
	    }

	    log_msg(_("App config saved") + ": '%s'".printf(app_conf_path));
	}

	public void load_app_config(){
		var f = File.new_for_path(app_conf_path);
		if (!f.query_exists()) { return; }

		var parser = new Json.Parser();
        try{
			parser.load_from_file(this.app_conf_path);
		} catch (Error e) {
	        log_error (e.message);
	    }
        var node = parser.get_root();
        var config = node.get_object();

		capture_background = json_get_bool(config,"capture_background",false);
		generate_png = json_get_bool(config,"generate_png",true);
		show_preview = json_get_bool(config,"show_preview",show_preview);
		show_list = json_get_bool(config,"show_list",show_list);
		pane_position = json_get_int(config,"pane_position",pane_position);
		window_width = json_get_int(config,"window_width",window_width);
		window_height = json_get_int(config,"window_height",window_height);
		startup_delay = json_get_int(config,"startup_delay",startup_delay);

		// search folders -------------------

		search_folders.clear();

		string home = Environment.get_home_dir();

		//default locations: look for other folders in addition to "~/.conky"
		foreach(string path in new string[]{ home + "/.Conky", home + "/.config/conky", home + "/.config/Conky"}){
			if (!search_folders.contains(path) && dir_exists(path)){
				search_folders.add(path);
			}
		}

		//add from config file
		if (config.has_member ("search-locations")){
			foreach (Json.Node jnode in config.get_array_member ("search-locations").get_elements()) {
				string path = jnode.get_string().replace("~",home);
				if (!search_folders.contains(path) && dir_exists(path) && (path != data_dir)){
					this.search_folders.add(path);
				}
			}
		}

		log_msg(_("App config loaded") + ": '%s'".printf(this.app_conf_path));
	}

	public void init_directories(){
		string path = data_dir;
		string home = Environment.get_home_dir ();

		if (dir_exists(path) == false){
			create_dir(path);
			log_debug(_("Directory Created") + ": " + path);
		}

		path = home + "/.fonts";
		if (dir_exists(path) == false){
			create_dir(path);
			log_debug(_("Directory Created") + ": " + path);
		}

		path = home + "/.config/autostart";
		if (dir_exists(path) == false){
			create_dir(path);
			log_debug(_("Directory Created") + ": " + path);
		}
	}

	public void init_theme_packs(){
		string sharePath = "/usr/share/conky-manager2/themepacks";
		string config_file = data_dir + "/.themepacks";

		//create empty config file if missing
		if (file_exists(config_file) == false) {
			Posix.system("touch \"" + config_file + "\"");
		}

		//read config file
		string txt = read_file(config_file);
		Gee.ArrayList<string> filenames = new Gee.ArrayList<string>();
		foreach(string item in txt.split("\n")){
			filenames.add(item);
		}

		//skip import of theme packs installed by previous versions of conky manager
		filenames.add("default-themes-1.1.cmtp.7z");
		filenames.add("default-themes-1.2.cmtp.7z");

		try{
			FileEnumerator enumerator;
			FileInfo file;
			File fShare = File.parse_name (sharePath);

			if (dir_exists(sharePath)){
				enumerator = fShare.enumerate_children ("standard::*", 0);

				while ((file = enumerator.next_file ()) != null) {

					string filePath = sharePath + "/" + file.get_name();
					if (file_exists(filePath) == false) { continue; }
					if (filePath.has_suffix(".cmtp.7z") == false) { continue; }

					bool is_installed = false;
					foreach(string filename in filenames){
						if (file.get_name() == filename){
							log_msg(_("Found theme pack [installed]") + ": " + filePath);
							is_installed = true;
							break;
						}
					}

					if (!is_installed){
						log_msg("-----------------------------------------------------");
						log_msg(_("Found theme pack [new]") + ": " + filePath);
						install_theme_pack(filePath);
						filenames.add(file.get_name());
						log_msg("-----------------------------------------------------");

						string list = "";
						foreach(string filename in filenames){
							list += filename + "\n";
						}
						list += file.get_name() + "\n";
						write_file(config_file,list);
					}
				}
			}
		}
        catch(Error e){
	        log_error (e.message);
	    }
	}

	public bool install_theme_pack(string pkgPath, bool tarformat = false){
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;

		//create temp dir
		string temp_dir = TEMP_DIR;
		temp_dir = temp_dir + "/" + timestamp2();
		create_dir(temp_dir);

		//check and create ~/.conky
		if (dir_exists(data_dir) == false){
			create_dir(data_dir);
		}

		log_msg(_("Importing") + ": " + pkgPath);

		//unzip
		cmd = "cd \"" + temp_dir + "\"\n";
		if (tarformat) 
            cmd += "7za x -so \"" + pkgPath + "\"  | tar xf - >nul\n";
		else
            cmd += "7za x \"" + pkgPath + "\">nul\n";

		ret_val = execute_command_script_sync(cmd, out std_out, out std_err);
		if (ret_val != 0){
			log_error(_("Failed to unzip files from theme pack"));
			log_error (std_err);
			return false;
		}

		//install
        int archive_path_counter = 0;
		foreach(string dirname in new string[]{".conky",".Conky",".fonts",".config/conky",".config/Conky"}){
			string src_path = temp_dir + "/" + dirname;
			string dst_path = Environment.get_home_dir() + "/" + dirname;

			if (dir_exists(src_path)){

				//create destination
				if (!dir_exists(dst_path)){
					create_dir(dst_path);
				}

				//rsync folder
				execute_command_sync("rsync -ai --numeric-ids '%s/' '%s'".printf(src_path,dst_path));
                archive_path_counter++;
			}
		}
        //if archive is not "conky theme" style containing files under .conky path just force to ~/.conky
        if (archive_path_counter == 0)
        {
			string src_path = temp_dir;
			string dst_path = Environment.get_home_dir() + "/.conky";

			//create destination
			if (!dir_exists(dst_path)){
				create_dir(dst_path);
			}

			//rsync folder
			execute_command_sync("rsync -ai --numeric-ids '%s/' '%s'".printf(src_path,dst_path));
        }

		//delete temp files
		Posix.system("rm -rf \"" + temp_dir + "\"");

		return true;
	}

	public void load_themes_and_widgets() {
		is_aborted = false;

		find_conkyrc_files();
		find_conkytheme_files();
		find_and_install_fonts();
		refresh_conkyrc_status();

		log_msg(_("Searching for conkyrc files... %d found").printf(conkyrc_list.size));
	}

	public void load_themes_and_widgets_cancel(){
		is_aborted = true;
		command_kill("grep",last_cmd);
	}

	public void find_conkyrc_files(){
		conkyrc_list = new Gee.ArrayList<ConkyRC>();

		find_conkyrc_files_in_path(data_dir);
		foreach(string path in search_folders){
			if (!is_aborted){
				find_conkyrc_files_in_path(path);
			}
		}
		CompareDataFunc<ConkyConfigItem> func = (a, b) => {
			return strcmp(a.name,b.name);
		};
		conkyrc_list.sort((owned) func);
	}

	public void find_conkyrc_files_in_path(string path){
		string std_out = "";
		string std_err = "";
		string cmd = "grep -r \"^[[:blank:]]*TEXT[[:blank:]]*$\\|conky\\.text[[:blank:]]*=\" \"%s\"".printf(path);
		last_cmd = cmd;
		int exit_code = execute_command_script_sync(cmd, out std_out, out std_err);

		if (exit_code != 0){
			//no files found
			return;
		}

		string file_path;
		foreach(string line in std_out.split("\n")){
			if (line.index_of(":") > -1){
				file_path = line.split(":")[0].strip();
				if (file_path.strip().has_suffix("~")){ continue; }

				bool found = false;
				foreach(ConkyConfigItem item in conkyrc_list){
					if (item.path == file_path){
						found = true;
						break;
					}
				}
				if (!found){
					ConkyRC rc = new ConkyRC(file_path);
					conkyrc_list.add(rc);
				}
			}
		}
	}

	public void find_conkytheme_files(){
		conkytheme_list = new Gee.ArrayList<ConkyTheme>();

		find_conkytheme_files_in_path(data_dir);
		foreach(string path in search_folders){
			if (!is_aborted){
				find_conkytheme_files_in_path(path);
			}
		}

		CompareDataFunc<ConkyConfigItem> func = (a, b) => {
			return strcmp(a.name,b.name);
		};
		conkytheme_list.sort((owned) func);
	}

    public void find_conkytheme_files_in_path(string path){
		string std_out = "";
		string std_err = "";
		string cmd = "rsync -aim --dry-run --include=\"*.cmtheme\" --include=\"*/\" --exclude=\"*\" \"%s/\" /tmp".printf(path);
		int exit_code = execute_command_script_sync(cmd, out std_out, out std_err);

		if (exit_code != 0){
			//no files found
			return;
		}

		string file_path;
		foreach(string line in std_out.split("\n")){
			if (line == null){ continue; }
			if (line.length == 0){ continue; }

			file_path = line.strip();
			if (file_path.has_suffix("~")){ continue; }
			if (!file_path.has_suffix(".cmtheme")){ continue; }
			if (file_path.split(" ").length < 2){ continue; }
			file_path = path + "/" + file_path[file_path.index_of(" ") + 1:file_path.length].strip();

			bool found = false;
			foreach(ConkyConfigItem item in conkytheme_list){
				if (item.path == file_path){
					found = true;
					break;
				}
			}
			if (!found){
				ConkyTheme th = new ConkyTheme.from_file(file_path,this);
				conkytheme_list.add(th);
			}
		}
	}

    public void find_and_install_fonts(){
		find_and_install_fonts_in_path(data_dir);
		foreach(string path in search_folders){
			if (!is_aborted){
				find_and_install_fonts_in_path(path);
			}
		}
	}

    public void find_and_install_fonts_in_path(string path){
		string std_out = "";
		string std_err = "";
		string cmd = "rsync -aim --dry-run --include=\"*.ttf\" --include=\"*.TTF\" --include=\"*.otf\"  --include=\"*.OTF\" --include=\"*/\" --exclude=\"*\" \"%s/\" /tmp".printf(path);
		int exit_code = execute_command_script_sync(cmd, out std_out, out std_err);

		if (exit_code != 0){
			//no files found
			return;
		}

		string file_path;
		foreach(string line in std_out.split("\n")){
			if (line == null){ continue; }
			if (line.length == 0){ continue; }

			file_path = line.strip();
			if (file_path.has_suffix("~")){ continue; }
			if (file_path.split(" ").length < 2){ continue; }

			if (file_path.has_suffix(".ttf")||file_path.has_suffix(".TTF")||file_path.has_suffix(".otf")||file_path.has_suffix(".OTF")){
				//ok
			}
			else{
				continue;
			}

			file_path = path + "/" + file_path[file_path.index_of(" ") + 1:file_path.length].strip();

			File font_file = File.new_for_path (file_path);
			string file_name = font_file.get_basename();
			string home = Environment.get_home_dir ();
			string target_file = home + "/.fonts/" + file_name;

			if (file_exists(target_file) == false){
				copy_file(file_path, target_file);
				log_msg(_("Font Copied: ") + target_file);
			}
		}
	}

	public void refresh_conkyrc_status() {
		Gee.ArrayList<string> active_list = new Gee.ArrayList<string>();

		string cmd = "conky -c "; //without double-quotes
		string txt = execute_command_sync_get_output ("ps w -C conky");
		//use 'ps ew -C conky' for all users

		foreach(string line in txt.split("\n")){
			if (line.index_of(cmd) != -1){
				string conf = line.substring(line.index_of(cmd) + 8).strip();
				active_list.add(conf);
			}
		}

		foreach(ConkyRC rc in conkyrc_list){
			bool active = false;
			foreach(string path in active_list){
				if (rc.path == path){
					active = true;
				}
			}
			rc.enabled = active;
		}
	}

	private void exit_app(){
		update_startup_script();

		save_app_config();

		if (check_startup()){
			autostart(true); //overwrite the startup entry
		}
	}

	public void run_startup_script(){
		execute_command_sync("sh \"" + data_dir + "/conky-startup.sh\"");
		Posix.usleep(500000);//microseconds
		//refresh_status();
	}

	public void update_startup_script(){
		string startupScript = data_dir + "/conky-startup.sh";
		string home = Environment.get_home_dir ();
        unowned string desktop_session = Environment.get_variable ("DESKTOP_SESSION");
        if (desktop_session == "(null)") desktop_session = "";
		bool atleast_one_widget_enabled = false;

		string txt_start_conky = "";
		txt_start_conky += "if [ \"$DESKTOP_SESSION\" = \"%s\" ]; then \n".printf(desktop_session);
		txt_start_conky += "   sleep %ds\n".printf(startup_delay);
		txt_start_conky += "   killall conky\n";
		foreach(ConkyRC conf in conkyrc_list){
			if (conf.enabled){
				txt_start_conky += "   cd \"" + conf.dir.replace(home, "$HOME")  + "\"\n";
				txt_start_conky += "   conky -c \"" + conf.path.replace(home, "$HOME") + "\" &\n";
				atleast_one_widget_enabled = true;
			}
		}
		txt_start_conky += "   exit 0\n";
		txt_start_conky += "fi\n";
		
		string txt_no_conky = "";
		txt_no_conky += "if [ \"$DESKTOP_SESSION\" = \"%s\" ]; then \n".printf(desktop_session);
		txt_no_conky += "   # No widgets enabled!\n";
		txt_no_conky += "   exit 0\n";
		txt_no_conky += "fi\n";
		
		
		string std_out = "";
		string std_err = "";
		
		string cmd1 = "grep  -sq -E '^[[:space:]]*if[[:space:]]+\\[[[:space:]]+\"?\\$\\{?DESKTOP_SESSION\\}?\"?' \"%s\" || rm  \"%s\"".printf (startupScript, startupScript);
		string cmd2 = "sed -i -r '/^[[:space:]]*if[[:space:]]+\\[[[:space:]]+\"?\\$\\{?DESKTOP_SESSION\\}?\"?[[:space:]]*==?[[:space:]]*\"%s\"[[:space:]]+\\]/,/^[[:space:]]*fi/d' \"%s\"".printf (desktop_session, startupScript);

		if (file_exists(startupScript)){
			try{
				execute_command_script_sync(cmd1, out std_out, out std_err);
			}
			catch (Error e) {
				log_error (e.message);
			}
		}	

		if (file_exists(startupScript)){
			try{
				execute_command_script_sync(cmd2, out std_out, out std_err);
			}
			catch (Error e) {
				log_error (e.message);
			}
		} else {
			write_file(startupScript, "#!/bin/sh\n\n"); // write shebang 
		}	

		if (atleast_one_widget_enabled){
			append_file(startupScript, txt_start_conky);
		}
		else{
			append_file(startupScript, txt_no_conky); 
		}
		
		execute_command_sync ("chmod +x \"%s\"".printf (startupScript));
	}

	public bool check_startup(){
		string home = Environment.get_home_dir ();
		string startupFile = home + "/.config/autostart/conky.desktop";
		return file_exists(startupFile);
	}

	public void autostart(bool autostart){
		string home = Environment.get_home_dir ();
		string startupFile = home + "/.config/autostart/conky.desktop";

		if (autostart){
			string txt =
"""[Desktop Entry]
Type=Application
Exec={command}
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_IN]=Conky
Name=Conky
Comment[en_IN]=
Comment=
""";
			txt = txt.replace("{command}", "sh \"" + data_dir + "/conky-startup.sh\"");

			write_file(startupFile, txt);
		}
		else{
			file_delete(startupFile);
		}
	}

	public void kill_all_conky(){
		Posix.system("killall conky");
		foreach(ConkyRC rc in conkyrc_list){
			rc.enabled = false;
		}
		log_msg("Stopping all conkys... OK");
	}
}

public abstract class ConkyConfigItem: GLib.Object{
	private string _name = "";
	private string _path = "";
	private string _dir = "";
	private string _image_path = "";
	private string _base_name = "";
	private bool _enabled = false;
	private string _url = "";
	private string _credits = "";

	public abstract void start();
	public abstract void terminal_start();
	public abstract void stop();

	public void init_path(string theme_file_path){
		path = theme_file_path;
		var f = File.new_for_path (theme_file_path);
		name = path.replace(Environment.get_home_dir(),"~");
		base_name = f.get_basename();
		dir = f.get_parent().get_path();
	}

	public void init_image_path(){

		string[] ext_list = {".png",".jpg",".jpeg"};

		//search using base name
		foreach(string ext in ext_list){
			image_path = dir + "/" + base_name + ext;
			if (file_exists(image_path)){ return; }
		}

		//search without basename extension
		if (base_name.split(".").length == 2){
			foreach(string ext in ext_list){
				image_path = dir + "/" + base_name.split(".")[0] + ext;
				if (file_exists(image_path)){ return; }
			}
		}

		//search using fixed names
		foreach(string ext in ext_list){
			image_path = dir + "/preview" + ext;
			if (file_exists(image_path)){ return; }
		}

		image_path = ""; //clear if not found
	}

	public void init_credits(){
		string source_file = dir + "/source.txt";
		if (file_exists(source_file)){
			url = TeeJee.FileSystem.read_file(source_file).replace("\n","");
		}

		string credits_file = dir + "/credits.txt";
		if (file_exists(credits_file)){
			credits = TeeJee.FileSystem.read_file(credits_file).replace("\n","");
		}
	}

	public string name{
		get{
			return _name;
		}
		set{
			_name = value;
		}
	}

	public string path{
		get{
			return _path;
		}
		set{
			_path = value;
		}
	}

	public string dir{
		get{
			return _dir;
		}
		set{
			_dir = value;
		}
	}

	public string image_path{
		get{
			return _image_path;
		}
		set{
			_image_path = value;
		}
	}

	public bool enabled{
		get{
			return _enabled;
		}
		set{
			_enabled = value;
		}
	}

	public string base_name{
		get{
			return _base_name;
		}
		set{
			_base_name = value;
		}
	}

	public string url{
		get{
			return _url;
		}
		set{
			_url = value;
		}
	}

	public string credits{
		get{
			return _credits;
		}
		set{
			_credits = value;
		}
	}

}

public class ConkyRC : ConkyConfigItem {
	public string text = "";
	public bool one_ten_config = false;

	private Regex rex_conky_win;
	private Regex rex_conky_text;
	private MatchInfo match;

	private string err_line;
	private string out_line;
	private DataInputStream dis_out;
	private DataInputStream dis_err;
	private bool thread_is_running = false;
	private int wait_interval = 1;
	private uint timer_stop;

	public ConkyRC(string rc_file_path) {
		init_path(rc_file_path);
		init_image_path();
		init_credits();

		try{
			rex_conky_win = new Regex("""\(0x([0-9a-zA-Z]*)\)""");
			rex_conky_text = new Regex("""^[[:space:]]*conky[.]text[[:space:]]*=[[:space:]]""");
		}
		catch (Error e) {
			log_error (e.message);
		}
	}

	public bool is_running(){
		string cmd = "conky -c " + path; //without double-quotes
		string txt = execute_command_sync_get_output ("ps w -C conky");
		//use 'ps ew -C conky' for all users

		bool active = false;
		foreach(string line in txt.split("\n")){
			if (line.index_of(cmd) != -1){
				active = true;
				break;
			}
		}
		return active;
	}

	public override void start(){
		string cmd;

		if (is_running()){
			stop();
		}

		//Theme.install();

		cmd = "cd \"" + dir + "\"\n";
		cmd += "conky -c \"" + path + "\"\n";

		execute_command_script_async(cmd);

		Thread.usleep((ulong)1000000);
		log_debug(_("Started") + ": " + path);

		//set the flag for immediate effect
		//will be updated by the refresh_status() timer
		enabled = true;
	}

	public override void terminal_start(){
		string cmd;

		if (is_running()){
			stop();
		}

		//Theme.install();

		cmd = "cd \"" + dir + "\"\n";
		cmd += "conky -c \"" + path + "\"\n";

		execute_command_script_in_terminal_sync( create_temp_bash_script(cmd) );

		Thread.usleep((ulong)1000000);
		log_debug(_("Started") + ": " + path);

		//set the flag for immediate effect
		//will be updated by the refresh_status() timer
		enabled = true;
	}

	public bool stop_handler(){
		stop();
		return true;
	}

	public override void stop(){

		//Note: There may be more than one running instance of the same config
		//We need to kill all instances

		string cmd = "conky -c " + path; //without double-quotes
		string txt = execute_command_sync_get_output ("ps w -C conky");
		//use 'ps ew -C conky' for all users

		string pid = "";
		foreach(string line in txt.split("\n")){
			if (line.index_of(cmd) != -1){
				pid = line.strip().split(" ")[0];
				Posix.kill ((Pid) int.parse(pid), 15);
				log_debug(_("Stopped") + ": [PID=" + pid + "] " + path);
			}
		}

		//set the flag for immediate effect
		//will be updated by the refresh_status() timer
		enabled = false;
	}

	public void read_file(){
		log_debug("Read config file from disk");
		this.text = TeeJee.FileSystem.read_file(this.path);
		this.one_ten_config = false;

		foreach(string line in text.split("\n")){
			if (rex_conky_text.match (line, 0, out match)){
				this.one_ten_config = true;
				break;
			}
		}
	}

	public void save_file(){
		log_debug("Saved config file changes to disk");
		write_file(this.path, text);
	}

	public void save_file_temp(){
		write_file(this.path + "~temp~", text);
	}

	public void delete_file_temp(){
		file_delete(this.path + "~temp~");
	}

	public bool generate_preview(){
		stop();
		read_file();
		if (App.capture_background){
			transparency = "pseudo";
		}
		else{
			transparency = "opaque";
		}
		delete_file_temp();
		save_file_temp();

		read_file();
		wait_interval = 3;
		foreach(string line in text.split("\n")){
			if (line.contains("lua_load") && !(line.strip().has_prefix("#")) && !(line.strip().has_prefix("--"))){
				wait_interval = 4;
				break;
			}
		}
		
		try {
			thread_is_running = true;
			Thread.create<void> (generate_preview_thread, true);
		} catch (ThreadError e) {
			thread_is_running = false;
			log_error (e.message);
		}

		while (thread_is_running){
			Thread.usleep ((ulong) 200000);
			gtk_do_events();
		}

		//check if file was generated
		if ((image_path.length > 0) && (file_exists(image_path))){
			log_msg(_("Saved") + ": " + image_path);
			return true;
		}
		else{
			image_path = "";
			return false;
		}
	}

	public void generate_preview_thread (){
		string cmd = "cd \"" + dir + "\"\n";
		cmd += "conky -c \"" + path + "~temp~\" 2>&1 \n";

		string[] argv = new string[1];
		argv[0] = create_temp_bash_script(cmd);

		Pid child_pid;
		int input_fd;
		int output_fd;
		int error_fd;

		try {
			//execute script file
			Process.spawn_async_with_pipes(
			    null, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,   // child_setup
			    out child_pid,
			    out input_fd,
			    out output_fd,
			    out error_fd);

			thread_is_running = true;

			timer_stop = Timeout.add (10 * 1000, stop_handler);

			//create stream readers
			UnixInputStream uis_out = new UnixInputStream(output_fd, false);
			UnixInputStream uis_err = new UnixInputStream(error_fd, false);
			dis_out = new DataInputStream(uis_out);
			dis_err = new DataInputStream(uis_err);
			dis_out.newline_type = DataStreamNewlineType.ANY;
			dis_err.newline_type = DataStreamNewlineType.ANY;

        	try {
				//start thread for reading output stream
			    Thread.create<void> (conky_read_output_line, true);
		    } catch (Error e) {
		        log_error (e.message);
		    }

		    try {
				//start thread for reading error stream
			    Thread.create<void> (conky_read_error_line, true);
		    } catch (Error e) {
		        log_error (e.message);
		    }
		}
		catch (Error e) {
			log_error (e.message);
		}
	}

	private void conky_read_error_line(){
		try{
			err_line = dis_err.read_line (null);
		    while (err_line != null) {
				//do nothing
		        err_line = dis_err.read_line (null); //read next
			}
		}
		catch (Error e) {
			log_error (e.message);
		}
	}

	private void conky_read_output_line(){
		try{
			out_line = dis_out.read_line (null);
		    while (out_line != null) {
				if (rex_conky_win.match (out_line, 0, out match)){

					//wait for one second till window is displayed on screen
					Thread.usleep ((ulong) wait_interval * 1000000);

					string win_id = match.fetch(1).strip();
					string cmd = "";

					if (App.generate_png){
						image_path = dir + "/" + base_name + ".png";
						cmd = "import -window 0x%s '%s'".printf(win_id,image_path);
					}
					else{
						image_path = dir + "/" + base_name + ".jpg";
						cmd = "import -window 0x%s -quality 90 '%s'".printf(win_id,image_path);
					}

					execute_command_sync(cmd);

					Thread.usleep ((ulong) 100000); //wait 100ms before killing conky

					if (timer_stop > 0){
						Source.remove(timer_stop);
						timer_stop = 0;
					}
					stop();
				}
				out_line = dis_out.read_line (null);  //read next
			}

			thread_is_running = false;
			delete_file_temp();
		}
		catch (Error e) {
			log_error (e.message);
		}
	}

	public string alignment{
		owned get{
			string s = get_value("alignment");

			switch(s){
				case "tl":
					s = "top_left";
					break;
				case "tr":
					s = "top_right";
					break;
				case "tm":
					s = "top_middle";
					break;
				case "bl":
					s = "bottom_left";
					break;
				case "br":
					s = "bottom_right";
					break;
				case "bm":
					s = "bottom_middle";
					break;
				case "ml":
					s = "middle_left";
					break;
				case "mr":
					s = "middle_right";
					break;
				case "mm":
					s = "middle_middle";
					break;
				case "":
					s = "top_left";
					break;
			}

			log_debug("Get: alignment " + s);

			return s;
		}
		set
		{
			string newLine = "alignment " + value;
			set_value("alignment", newLine);
			log_debug("Set: alignment " + value);
		}
	}

	public string gap_x{
		owned get{
			string s = get_value("gap_x");
			if (s == "") { s = "0"; }
			log_debug("Get: gap_x " + s);
			return s;
		}
		set
		{
			string newLine = "gap_x " + value;
			set_value("gap_x", newLine);
			log_debug("Set: gap_x " + value);
		}
	}

	public string gap_y{
		owned get{
			string s = get_value("gap_y");
			if (s == "") { s = "0"; }
			log_debug("Get: gap_y " + s);
			return s;
		}
		set
		{
			string newLine = "gap_y " + value;
			set_value("gap_y", newLine);
			log_debug("Set: gap_y " + value);
		}
	}

	public string own_window_transparent{
		owned get{
			string s = get_value("own_window_transparent");
			if (s == "") { s = ""; }
			log_debug("Get: own_window_transparent " + s);
			return s;
		}
		set
		{
			string newLine = "own_window_transparent " + value;
			set_value("own_window_transparent", newLine);
			log_debug("Set: own_window_transparent " + value);
		}
	}

	public string own_window_argb_visual{
		owned get{
			string s = get_value("own_window_argb_visual");
			if (s == "") { s = ""; }
			log_debug("Get: own_window_argb_visual " + s);
			return s;
		}
		set
		{
			string newLine = "own_window_argb_visual " + value;
			set_value("own_window_argb_visual", newLine);
			log_debug("Set: own_window_argb_visual " + value);
		}
	}

	public string own_window_argb_value{
		owned get{
			string s = get_value("own_window_argb_value");
			if (s == "") { s = ""; }
			log_debug("Get: own_window_argb_value " + s);
			return s;
		}
		set
		{
			string newLine = "own_window_argb_value " + value;
			set_value("own_window_argb_value", newLine);
			log_debug("Set: own_window_argb_value " + value);
		}
	}

	public string own_window_colour{
		owned get{
			string s = get_value("own_window_colour");
			if (s == "") { s = "000000"; }
			log_debug("Get: own_window_colour " + s);
			return s.up();
		}
		set{
			string newLine = "own_window_colour " + value.up();
			set_value("own_window_colour", newLine);
			log_debug("Set: own_window_colour " + value.up());
		}
	}

	public string transparency{
		owned get{
			string s = "trans";

			if(own_window_transparent == "yes"){
				if(own_window_argb_visual == "yes"){
					//own_window_argb_value, if present, will be ignored by Conky
					s = "trans";
				}
				else if (own_window_argb_visual == "no"){
					s = "pseudo";
				}
				else{
					s = "pseudo";
				}
			}
			else if (own_window_transparent == "true"){
				if(own_window_argb_visual == "true"){
					//own_window_argb_value, if present, will be ignored by Conky
					s = "trans";
				}
				else if (own_window_argb_visual == "false"){
					s = "pseudo";
				}
				else{
					s = "pseudo";
				}
			}
			else if (own_window_transparent == "no"){
				if(own_window_argb_visual == "yes"){
					if (own_window_argb_value == "0"){
						s = "trans";
					}
					else if (own_window_argb_value == "255"){
						s = "opaque";
					}
					else{
						s = "semi";
					}
				}
				else if (own_window_argb_visual == "no"){
					s = "opaque";
				}
				else{
					s = "opaque";
				}
			}
			else if (own_window_transparent == "false"){
				if(own_window_argb_visual == "true"){
					if (own_window_argb_value == "0"){
						s = "trans";
					}
					else if (own_window_argb_value == "255"){
						s = "opaque";
					}
					else{
						s = "semi";
					}
				}
				else if (own_window_argb_visual == "false"){
					s = "opaque";
				}
				else{
					s = "opaque";
				}
			}
			else{
				s = "opaque";
			}

			log_debug("Get: transparency " + s);

			return s;
		}
		set{
			switch (value.down()){
				case "opaque":
					if (one_ten_config){
						own_window_transparent = "false";
						own_window_argb_visual = "false";
					}
					else {
						own_window_transparent = "no";
						own_window_argb_visual = "no";
					}
					break;
				case "trans":
					if (one_ten_config){
						own_window_transparent = "true";
						own_window_argb_visual = "true";
						own_window_argb_value = "0";
					}
					else {
						own_window_transparent = "yes";
						own_window_argb_visual = "yes";
						own_window_argb_value = "0";
					}
					break;
				case "pseudo":
					if (one_ten_config){
						own_window_transparent = "true";
						own_window_argb_visual = "false";
					}
					else {
						own_window_transparent = "yes";
						own_window_argb_visual = "no";
					}
					break;
				case "semi":
				default:
					if (one_ten_config){
						own_window_transparent = "false";
						own_window_argb_visual = "true";
					}
					else {
						own_window_transparent = "no";
						own_window_argb_visual = "yes";
					}
					break;
			}

			log_debug("Set: transparency " + value.down());
		}
	}

	public string minimum_size{
		owned get{
			string s = get_value("minimum_size");
			if ((s == "")||(s.split(" ").length != 2)) { s = "0 0"; }
			log_debug("Get: minimum_size " + s);
			return s;
		}
		set
		{
			string newLine = "minimum_size " + value;
			set_value("minimum_size", newLine);
			log_debug("Set: minimum_size " + value);
		}
	}

	public string minimum_width{
		owned get{
			string s = get_value("minimum_width");
			if (s == "") { s = "0"; }
			log_debug("Get: minimum_width " + s);
			return s;
		}
		set
		{
			string newLine = "minimum_width " + value;
			set_value("minimum_width", newLine);
			log_debug("Set: minimum_width " + value);
		}
	}

	public string minimum_height{
		owned get{
			string s = get_value("minimum_height");
			if (s == "") { s = "0"; }
			log_debug("Get: minimum_height " + s);
			return s;
		}
		set
		{
			string newLine = "minimum_height " + value;
			set_value("minimum_height", newLine);
			log_debug("Set: minimum_height " + value);
		}
	}

	public int height_padding{
		get{
			string[] arr = this.text.split("\n");
			int count = 0;
			int k = arr.length - 1;

			//skip empty lines to find ]] ending marker
			if (one_ten_config){
				for(k = arr.length - 1; k >= 0; k--){
					if (arr[k].strip() == ""){
						//skip blank lines after "]]"
					}
					else if (arr[k].strip() == "]]"){
						k--;
						count++;//fudge this so works with following previous existing code below
						break;
					}
				}
			}

			//count empty lines at end of text section
			for(k=k; k >= 0; k--){
				if (arr[k].strip() == ""){
					count++;
				}
				else{
					break;
				}
			}

			count--;

			log_debug("Get: height_padding " + count.to_string());

			return count;
		}
		set
		{
			string newText = "";
			string[] arr = this.text.split("\n");
			int count = 0;
			int skipExisting = 0;

			//count empty lines at end of the file
			if (one_ten_config){
				bool counting = false;
				for(int k = arr.length - 1; k >= 0; k--){
					if (arr[k].strip() == ""){
						count++;
						if (counting) { skipExisting++; }
					}
					else if (arr[k].strip() == "]]"){
						count++;
						counting = true;
					}
					else{
						break;
					}
				}
			}
			else{
				for(int k = arr.length - 1; k >= 0; k--){
					if (arr[k].strip() == ""){
						count++;
					}
					else{
						break;
					}
				}
			}
			int lastLineNumber = arr.length - count;

			//remove all empty lines from end of text
			for(int k = 0; k < lastLineNumber; k++){
				newText += arr[k] + "\n";
			}
			//remove extra newline from end of text
			//newText = newText[0:newText.length-1];

			//add empty lines at end of text
			for(int k = 1; k <= value; k++){
				newText += "\n";
			}

			if (one_ten_config){
				//add the rest of file back from ]] to end
				for(int k = lastLineNumber+skipExisting; k < arr.length-1; k++){
					newText += arr[k] + "\n";
				}
			}

			log_debug("Set: height_padding " + value.to_string());

			this.text = newText;
		}
	}

	public string time_format{
		owned get{
			string val = "";

			if (search("""\${(time|TIME) [^}]*H[^}]*}""") != ""){
				val = "24";
				log_debug("Get: time format = 24-hour");
			}
			else if (search("""\${(time|TIME) [^}]*I[^}]*}""") != ""){
				val = "12";
				log_debug("Get: time format = 12-hour");
			}

			return val;
		}
		set
		{
			if (value == "") { return; }

			switch(value){
				case "12":
					if (replace("""\${(time|TIME) [^}]*(H)[^}]*}""", 2, "I")){
						log_debug("Set: time format = 12-hour");
					}
					break;
				case "24":
					if (replace("""\${(time|TIME) [^}]*(I)[^}]*}""", 2, "H")){
						log_debug("Set: time format = 24-hour");
					}
					break;
			}
		}
	}

	public string network_device{
		owned get{
			string var1 = "totaldown|totalup|upspeed|upspeedf|downspeed|downspeedf|wireless_ap|wireless_bitrate|wireless_essid|wireless_link_qual|wireless_link_qual_max|wireless_link_qual_perc|wireless_mode|if_up|addr";
			var1 = """\${(""" + var1 + "|" + var1.up() + """)[ \t]*([A-Za-z0-9]+)[ \t]*}""";

			string var2 = "upspeedgraph|downspeedgraph";
			var2 = """\${(""" + var2 + "|" + var2.up() + """)[ \t]*([A-Za-z0-9]+)[ \t]*.*}""";

			string var3 = "wireless_link_bar";
			var3 = """\${(""" + var3 + "|" + var3.up() + """)[ \t]*[0-9]+[ \t]*,[0-9+][ \t]*([A-Za-z0-9]+)[ \t]*}""";

			string net = search(var1, 2);

			if (net != ""){
				log_debug("Get: network interface = " + net);
				return net;
			}

			net = search(var2, 2);

			if (net != ""){
				log_debug("Get: network interface = " + net);
				return net;
			}

			net = search(var3, 2);

			if (net != ""){
				log_debug("Get: network interface = " + net);
				return net;
			}

			return "";
		}
		set
		{
			if (value == "") { return; }

			string var1 = "totaldown|totalup|upspeed|upspeedf|downspeed|downspeedf|wireless_ap|wireless_bitrate|wireless_essid|wireless_link_qual|wireless_link_qual_max|wireless_link_qual_perc|wireless_mode|if_up|addr";
			var1 = """\${(""" + var1 + "|" + var1.up() + """)[ \t]*([A-Za-z0-9]+)[ \t]*}""";

			string var2 = "upspeedgraph|downspeedgraph";
			var2 = """\${(""" + var2 + "|" + var2.up() + """)[ \t]*([A-Za-z0-9]+)[ \t]*.*}""";

			string var3 = "wireless_link_bar";
			var3 = """\${(""" + var3 + "|" + var3.up() + """)[ \t]*[0-9]+[ \t]*,[0-9+][ \t]*([A-Za-z0-9]+)[ \t]*}""";

			string net = search(var1, 2);

			if (net != ""){
				if (replace(var1, 2, value)){
					log_debug("Set: network interface = " + value);
				}
			}

			net = search(var2, 2);

			if (net != ""){
				if (replace(var2, 2, value)){
					log_debug("Set: network interface = " + value);
				}
			}

			net = search(var3, 2);

			if (net != ""){
				if (replace(var3, 2, value)){
					log_debug("Set: network interface = " + value);
				}
			}
		}
	}

	public string get_value(string param){
		foreach(string line in this.text.split("\n")){
			string s = line.down().strip();
			if (s.has_prefix(param)){
				if (s.index_of("=") != -1){
					return s[s.index_of("=")+1:s.length].strip().split(",")[0].replace("\'", " ").replace("\"", " ").strip();
				}
				else if (s.index_of(" ") != -1){
					return s[s.index_of(" ")+1:s.length].strip();
				}
				else if (s.index_of("\t") != -1){
					return s[s.index_of("\t")+1:s.length].replace("\t"," ").strip();
				}
			}
		}

		return "";
	}

	public void set_value(string param, string newLine){
		string newText = "";
		bool found = false;
		bool remove = (newLine.strip() == param);

		foreach(string line in this.text.split("\n")){
			string s = line.down().strip();
			if (s.has_prefix(param)){
				if (!remove){
					//replace line
					if (one_ten_config){
						newText += line.replace(get_value(param), newLine.split(" ")[1]) + "\n";
					}
					else{
						newText += newLine + "\n";
					}
				}
				found = true;
			}
			else if ((s == "text")&&(!found)){
				if (!remove){
					//insert line
					if (one_ten_config){
						newText += newLine.split(" ")[0] + " = " + newLine.split(" ")[1] + ",\n";
					}
					else{
						newText += newLine + "\n";
					}
				}
				newText += line + "\n";
				found = true;
			}
			else{
				newText += line + "\n";
			}
		}

		//remove extra newline from end of text
		newText = newText[0:newText.length-1];

		this.text = newText;
	}

	public string search(string search_string, int bracket_num = 0){
		foreach(string line in this.text.split("\n")){
			string s = line.strip();

			try{
				Regex regx = new Regex(search_string);
				MatchInfo match;
				if (regx.match(s, 0, out match)){
					return match.fetch(bracket_num);
				}
			} catch (Error e) {
				log_error (e.message);
			}
		}

		return "";
	}

	public bool replace(string search_string, int bracket_num, string replace_string){
		bool found = false;
		string new_text = "";
		string old_match = "";
		string new_match = "";
		string new_line = "";

		foreach(string line in this.text.split("\n")){
			try{
				Regex regx = new Regex(search_string);
				MatchInfo match;
				if (regx.match(line, 0, out match)){

					bool matchExists = true;
					new_line = line;

					while (matchExists){
						old_match = match.fetch(0);
						new_match = old_match.replace(match.fetch(bracket_num),replace_string);
						//log_debug("old_match=%s\nnew_match=%s\n".printf(old_match,new_match));
						new_line = new_line.replace(old_match, new_match);
						matchExists = match.next();
					}

					new_text += new_line + "\n";
					found = true;
				}
				else{
					new_text += line + "\n";
				}
			} catch (Error e) {
				log_error (e.message);
				return false;
			}
		}

		//remove extra newline from end of text
		new_text = new_text[0:new_text.length-1];

		this.text = new_text;

		return found;
	}
}

public class ConkyTheme : ConkyConfigItem {
	public string wallpaper_path = "";
	public string text = "";
	public string wallpaper_scaling = "";

	public Gee.ArrayList<ConkyRC> conkyrc_list;
	private Main main_app;

	public ConkyTheme.empty(string theme_file_path){
		init_path(theme_file_path);
		conkyrc_list = new Gee.ArrayList<ConkyRC>();
	}

	public ConkyTheme.from_file(string theme_file_path, Main _main_app){
		main_app = _main_app;
		init_path(theme_file_path);
		init_image_path();
		init_credits();

		conkyrc_list = new Gee.ArrayList<ConkyRC>();
		foreach(string line in read_file(theme_file_path).split("\n")){
			//remove quotes
			if (line.has_prefix("\"")){
				line = line[1:line.length];
			}
			if (line.has_suffix("\"")){
				line = line[0:line.length-1];
			}

			//read options
			if (line.contains("wallpaper-scaling") && (line.split(":").length == 2)){
				string val = line.split(":")[1].strip().down();

				//check if option is valid
				bool valid = false;
				foreach(string option in App.bg_scaling){
					if (val == option){
						valid = true;
						break;
					}
				}

				if (valid){
					wallpaper_scaling = val;
					continue;
				}
				else{
					continue;
				}
			}

			//read wallpaper path
			if (line.has_suffix(".png")||line.has_suffix(".jpg")||line.has_suffix(".jpeg")){
				wallpaper_path = line.replace("~", Environment.get_home_dir());
			}
			else{
				//read widget
				string file_path = line.replace("~", Environment.get_home_dir());
				foreach(ConkyRC item in _main_app.conkyrc_list){
					if (item.path == file_path){
						conkyrc_list.add(item);
						break;
					}
				}
			}
		}
	}

	public void init_wallpaper_path(){
		string[] ext_list = {".png",".jpg",".jpeg"};

		foreach(string ext in ext_list){
			wallpaper_path = dir + "/wallpaper" + ext;
			if (file_exists(wallpaper_path)){ return; }
		}

		wallpaper_path = "";
	}

	public void set_wallpaper(){
		if ((wallpaper_path.length > 0)&&(file_exists(wallpaper_path))){
			switch (App.desktop){
				case "cinnamon":
					//2.0
					if (execute_command_sync("gsettings get org.cinnamon.desktop.background picture-uri") == 0){
						execute_command_sync("gsettings set org.cinnamon.desktop.background picture-uri 'file://%s'".printf(wallpaper_path));
					}
					if (execute_command_sync("gsettings get org.cinnamon.desktop.background picture-options") == 0){
						execute_command_sync("gsettings set org.cinnamon.desktop.background picture-options '%s'".printf(get_scaling_value_for_desktop()));
					}
					//1.8
					if (execute_command_sync("gsettings get org.cinnamon.background picture-uri") == 0){
						execute_command_sync("gsettings set org.cinnamon.background picture-uri 'file://%s'".printf(wallpaper_path));
					}
					if (execute_command_sync("gsettings get org.cinnamon.background picture-options") == 0){
						execute_command_sync("gsettings set org.cinnamon.background picture-options '%s'".printf(get_scaling_value_for_desktop()));
					}
					break;
				case "xfce":
					//execute_command_sync("xfconf-query --channel xfce4-desktop --property '/backdrop/screen0/monitor0/image-path' --set '%s'".printf(wallpaper_path));
					//execute_command_sync("xfconf-query --channel xfce4-desktop --property '/backdrop/screen0/monitor0/image-style' --set %s".printf(get_scaling_value_for_desktop()));
					string std_out, std_err;
					execute_command_script_sync("""xfconf-query -c xfce4-desktop -p /backdrop -l|egrep -e "screen.*/monitor.*image-path$" -e "screen.*/monitor.*/last-image$"""",out std_out, out std_err);
					foreach(string property in std_out.split("\n")){
						string cmd = "";
						cmd += "xfconf-query -c xfce4-desktop -p '%s' -n -t string -s ''\n".printf(property.strip());
						cmd += "xfconf-query -c xfce4-desktop -p '%s' -s ''\n".printf(property.strip());
						cmd += "xfconf-query -c xfce4-desktop -p '%s' -s '%s'".printf(property.strip(), wallpaper_path);
						string std_out2, std_err2;
						execute_command_script_sync(cmd, out std_out2, out std_err2);
					}
					break;
				case "lxde": //limited support - wallpaper changes after logout and login
					execute_command_sync("pcmanfm --set-wallpaper '%s'".printf(wallpaper_path));
					if (get_scaling_value_for_desktop() != ""){
						execute_command_sync("pcmanfm --wallpaper-mode '%s'".printf(get_scaling_value_for_desktop()));
					}
					break;
				case "gnome":
				case "unity":
					if (execute_command_sync("gsettings get org.gnome.desktop.background picture-uri") == 0){
						execute_command_sync("gsettings set org.gnome.desktop.background picture-uri 'file://%s'".printf(wallpaper_path));
					}

					if (execute_command_sync("gsettings get org.gnome.desktop.background picture-options") == 0){
						execute_command_sync("gsettings set org.gnome.desktop.background picture-options '%s'".printf(get_scaling_value_for_desktop()));
					}

					if (execute_command_sync("gsettings get com.canonical.unity-greeter background") == 0){
						execute_command_sync("gsettings set com.canonical.unity-greeter background '%s'".printf(wallpaper_path));
					}
					break;
			}


			/*if (wallpaper_scaling.length > 0){
				Posix.system("feh --bg-%s '%s'".printf(wallpaper_scaling,wallpaper_path));
			}
			else{
				Posix.system("feh --bg-max '%s'".printf(wallpaper_path));
			}*/
		}
	}

	public string get_scaling_value_for_desktop(){
		//get index
		int index = 0;
		foreach(string option in App.bg_scaling){
			if (wallpaper_scaling == option){
				break;
			}
			else{
				index++;
			}
		}

		//return mapped value
		switch (App.desktop){
			case "gnome":
			case "cinnamon":
				return App.bg_scaling_gnome[index];
			case "xfce":
				return App.bg_scaling_xfce[index];
			case "lxde":
				return App.bg_scaling_lxde[index];
			default:
				return "";
		}

	}

	public string get_current_wallpaper(){
		switch (App.desktop){
			case "gnome":
			case "cinnamon":
			case "unity":
				string val = execute_command_sync_get_output("gsettings get org.%s.desktop.background picture-uri".printf(App.desktop));
				val = val[1:val.length-2]; //remove quotes
				val = val[7:val.length]; //remove prefix file://
				return uri_decode(val.strip());
			case "xfce":
				string val = execute_command_sync_get_output("xfconf-query --channel xfce4-desktop --property '/backdrop/screen0/monitor0/workspace0/last-image'");
				return uri_decode(val.strip());
			case "lxde":
				string val = execute_command_sync_get_output("grep wallpaper=/ ~/.config/pcmanfm/lubuntu/pcmanfm.conf | sed -e 's/wallpaper=//g'");
				if (val.strip() == ""){
					val = execute_command_sync_get_output("grep wallpaper=/ ~/.config/pcmanfm/lubuntu/desktop-items-0.conf | sed -e 's/wallpaper=//g'");
				}
				return uri_decode(val.strip());
			default:
				return "";
		}
	}

	public string save_current_wallpaper(){
		string path = get_current_wallpaper();
		log_msg(_("Current wallpaper source path") + ": '%s'".printf(path));
		int ext_index = path.last_index_of(".");
		wallpaper_path = dir + "/wallpaper" + path[ext_index: path.length].strip();
		file_copy(path,wallpaper_path);
		log_msg(_("Wallpaper saved") + ": '%s'".printf(wallpaper_path));
		return wallpaper_path;
	}

	public string save_wallpaper(string src_path){
		int ext_index = src_path.last_index_of(".");
		wallpaper_path = dir + "/wallpaper" + src_path[ext_index: src_path.length].strip();
		file_copy(src_path,wallpaper_path);
		log_msg(_("Wallpaper saved") + ": '%s'".printf(wallpaper_path));
		return wallpaper_path;
	}

	public override void start(){
		main_app.kill_all_conky();
		set_wallpaper();
		foreach(ConkyRC rc in conkyrc_list){
			rc.start();
		}
	}

	public override void terminal_start(){
		main_app.kill_all_conky();
		set_wallpaper();
		foreach(ConkyRC rc in conkyrc_list){
			rc.terminal_start();
		}
	}

	public override void stop(){
		main_app.kill_all_conky();
	}
}
