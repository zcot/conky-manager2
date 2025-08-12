/*
 * Utility.vala
 * 
 * Copyright 2015 Tony George <teejee2008@gmail.com>
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

using Gtk;
using Json;
using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;
/*
extern void exit(int exit_code);

public Main App;
public const string AppName = "Selene Media Encoder";
public const string AppShortName = "selene";
public const string AppVersion = "2.3";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejee2008@gmail.com";
public const bool LogTimestamp = true;
public bool UseConsoleColors = false;
*/

namespace TeeJee.Logging{
	
	/* Functions for logging messages to console and log files */

	using TeeJee.Misc;
	
	public DataOutputStream dos_log;
	
	public bool LOG_ENABLE = true;
	public bool LOG_TIMESTAMP = true;
	public bool LOG_COLORS = true;
	public bool LOG_DEBUG = false;
	public bool LOG_COMMANDS = false;

	public void log_msg (string message, bool highlight = false){

		if (!LOG_ENABLE) { return; }
		
		string msg = "";
		
		if (highlight && LOG_COLORS){
			msg += "\033[1;38;5;34m";
		}
		
		if (LOG_TIMESTAMP){
			msg += "[" + timestamp() +  "] ";
		}
		
		msg += message;
		
		if (highlight && LOG_COLORS){
			msg += "\033[0m";
		}
		
		msg += "\n";
		
		stdout.printf (msg);
		
		try {
			if (dos_log != null){
				dos_log.put_string ("[%s] %s\n".printf(timestamp(), message));
			}
		} 
		catch (Error e) {
			stdout.printf (e.message);
		}
	}

	public void log_error (string message, bool highlight = false, bool is_warning = false){
		if (!LOG_ENABLE) { return; }
		
		string msg = "";
		
		if (highlight && LOG_COLORS){
			msg += "\033[1;38;5;160m";
		}
		
		if (LOG_TIMESTAMP){
			msg += "[" + timestamp() +  "] ";
		}
		
		string prefix = (is_warning) ? _("Warning") : _("Error");
		
		msg += prefix + ": " + message;
		
		if (highlight && LOG_COLORS){
			msg += "\033[0m";
		}
		
		msg += "\n";
		
		stdout.printf (msg);
		
		try {
			if (dos_log != null){
				dos_log.put_string ("[%s] %s: %s\n".printf(timestamp(), prefix, message));
			}
		} 
		catch (Error e) {
			stdout.printf (e.message);
		}
	}

	public void log_debug (string message){
		if (!LOG_ENABLE) { return; }
			
		if (LOG_DEBUG){
			log_msg (message);
		}
		else{
			try {
				if (dos_log != null){
					dos_log.put_string ("[%s] %s\n".printf(timestamp(), message));
				}
			} 
			catch (Error e) {
				stdout.printf (e.message);
			}
		}
	}
}

namespace TeeJee.FileSystem{
	
	/* Convenience functions for handling files and directories */
	
	using TeeJee.Logging;
	using TeeJee.FileSystem;
	using TeeJee.ProcessManagement;
	using TeeJee.Misc;
	
	public void file_delete(string filePath){
		
		/* Check and delete file */
		
		try {
			var file = File.new_for_path (filePath);
			if (file.query_exists ()) { 
				file.delete (); 
			}
		} catch (Error e) {
	        log_error (e.message);
	    }
	}
	
	public bool file_exists (string filePath){
		
		/* Check if file exists */
		
		return ( FileUtils.test(filePath, GLib.FileTest.EXISTS) && FileUtils.test(filePath, GLib.FileTest.IS_REGULAR));
	}

	public void file_copy (string src_file, string dest_file){
		try{
			var file_src = File.new_for_path (src_file);
			if (file_src.query_exists()) { 
				var file_dest = File.new_for_path (dest_file);
				file_src.copy(file_dest,FileCopyFlags.OVERWRITE,null,null);
			}
		}
		catch(Error e){
	        log_error (e.message);
		}
	}
	
	public bool dir_exists (string filePath){
		
		/* Check if directory exists */
		
		return ( FileUtils.test(filePath, GLib.FileTest.EXISTS) && FileUtils.test(filePath, GLib.FileTest.IS_DIR));
	}
	
	public bool create_dir (string filePath){
		
		/* Creates a directory along with parents */
		
		try{
			var dir = File.parse_name (filePath);
			if (dir.query_exists () == false) {
				dir.make_directory_with_parents (null);
			}
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool move_file (string sourcePath, string destPath){
		
		/* Move file from one location to another */
		
		try{
			File fromFile = File.new_for_path (sourcePath);
			File toFile = File.new_for_path (destPath);
			fromFile.move (toFile, FileCopyFlags.NONE);
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool copy_file (string sourcePath, string destPath){
		
		/* Copy file from one location to another */
		
		try{
			File fromFile = File.new_for_path (sourcePath);
			File toFile = File.new_for_path (destPath);
			fromFile.copy (toFile, FileCopyFlags.NONE);
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public string? read_file (string file_path){
		
		/* Reads text from file */
		
		string txt;
		size_t size;
		
		try{
			GLib.FileUtils.get_contents (file_path, out txt, out size);
			return txt;	
		}
		catch (Error e){
	        log_error (e.message);
	    }
	    
	    return null;
	}
	
	public bool append_file (string file_path, string contents){
		
		/* Append text to file */
		File file = File.new_for_path (file_path);
		try{
			FileOutputStream file_stream = file.append_to (FileCreateFlags.NONE);
			file_stream.write (contents.data);
			return true;
		}
		catch (Error e) {
	        log_error (e.message);
	        return false;
	    } 
	}

	
	public bool write_file (string file_path, string contents){
		
		/* Write text to file */
		
		try{
			var file = File.new_for_path (file_path);
			if (file.query_exists ()) { file.delete (); }
			var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
			var data_stream = new DataOutputStream (file_stream);
			data_stream.put_string (contents);
			data_stream.close();
			return true;
		}
		catch (Error e) {
	        log_error (e.message);
	        return false;
	    } 
	}
	
	public long get_file_count(string path){
				
		/* Return total count of files and directories */
		
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		cmd = "find \"%s\" | wc -l".printf(path);
		ret_val = execute_command_script_sync(cmd, out std_out, out std_err);
		return long.parse(std_out);
	}

	public long get_file_size(string path){
				
		/* Returns size of files and directories in KB*/
		
		string cmd = "";
		string output = "";
		
		cmd = "du -s \"%s\"".printf(path);
		output = execute_command_sync_get_output(cmd);
		return long.parse(output.split("\t")[0]);
	}

	public string get_file_size_formatted(string path){
				
		/* Returns size of files and directories in KB*/
		
		string cmd = "";
		string output = "";
		
		cmd = "du -s -h \"%s\"".printf(path);
		output = execute_command_sync_get_output(cmd);
		return output.split("\t")[0].strip();
	}
	
	public int chmod (string file, string permission){
				
		/* Change file permissions */
		
		return execute_command_sync ("chmod " + permission + " \"%s\"".printf(file));
	}
	
	public string resolve_relative_path (string filePath){
				
		/* Resolve the full path of given file using 'realpath' command */
		
		string filePath2 = filePath;
		if (filePath2.has_prefix ("~")){
			filePath2 = Environment.get_home_dir () + "/" + filePath2[2:filePath2.length];
		}
		
		try {
			string output = "";
			Process.spawn_command_line_sync("realpath \"%s\"".printf(filePath2), out output);
			output = output.strip ();
			if (FileUtils.test(output, GLib.FileTest.EXISTS)){
				return output;
			}
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    
	    return filePath2;
	}
	
	public int rsync (string sourceDirectory, string destDirectory, bool updateExisting, bool deleteExtra){
				
		/* Sync files with rsync */
		
		string cmd = "rsync --recursive --perms --chmod=a=rwx";
		cmd += updateExisting ? "" : " --ignore-existing";
		cmd += deleteExtra ? " --delete" : "";
		cmd += " \"%s\"".printf(sourceDirectory + "//");
		cmd += " \"%s\"".printf(destDirectory);
		return execute_command_sync (cmd);
	}
}

namespace TeeJee.JSON{
	
	using TeeJee.Logging;

	/* Convenience functions for reading and writing JSON files */
	
	public string json_get_string(Json.Object jobj, string member, string def_value){
		if (jobj.has_member(member)){
			return jobj.get_string_member(member);
		}
		else{
			log_error ("Member not found in JSON object: " + member, false, true);
			return def_value;
		}
	}
	
	public bool json_get_bool(Json.Object jobj, string member, bool def_value){
		if (jobj.has_member(member)){
			return bool.parse(jobj.get_string_member(member));
		}
		else{
			log_error ("Member not found in JSON object: " + member, false, true);
			return def_value;
		}
	}
	
	public int json_get_int(Json.Object jobj, string member, int def_value){
		if (jobj.has_member(member)){
			return int.parse(jobj.get_string_member(member));
		}
		else{
			log_error ("Member not found in JSON object: " + member, false, true);
			return def_value;
		}
	}
	
}

namespace TeeJee.ProcessManagement{
	using TeeJee.Logging;
	using TeeJee.FileSystem;
	using TeeJee.Misc;
	
	public string TEMP_DIR;

	/* Convenience functions for executing commands and managing processes */
	
    public static void init_tmp(){
		string std_out, std_err;
		
		TEMP_DIR = Environment.get_tmp_dir() + "/" + AppShortName;
		create_dir(TEMP_DIR);
		
		execute_command_script_sync("echo 'ok'",out std_out,out std_err);
		if ((std_out == null)||(std_out.strip() != "ok")){
			TEMP_DIR = Environment.get_home_dir() + "/.temp/" + AppShortName;
			execute_command_sync("rm -rf '%s'".printf(TEMP_DIR));
			create_dir(TEMP_DIR);
		}
	}

	public int execute_command_sync (string cmd){
		
		/* Executes single command synchronously and returns exit code 
		 * Pipes and multiple commands are not supported */

		try {
			int exitCode;
			Process.spawn_command_line_sync(cmd, null, null, out exitCode);
	        return exitCode;
		}
		catch (Error e){
	        log_error (e.message);
	        return -1;
	    }
	}
	
	public string execute_command_sync_get_output (string cmd){
				
		/* Executes single command synchronously and returns std_out
		 * Pipes and multiple commands are not supported */
		
		try {
			int exitCode;
			string std_out;
			Process.spawn_command_line_sync(cmd, out std_out, null, out exitCode);
	        return std_out;
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}

	public bool execute_command_script_async (string cmd){
				
		/* Creates a temporary bash script with given commands and executes it asynchronously 
		 * Return value indicates if script was started successfully */
		
		try {
			
			string scriptfile = create_temp_bash_script (cmd);
			
			string[] argv = new string[1];
			argv[0] = scriptfile;
			
			Pid child_pid;
			Process.spawn_async_with_pipes(
			    null, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,
			    out child_pid);
			return true;
		}
		catch (Error e){
	        log_error (e.message);
	        return false;
	    }
	}
	
	public string? create_temp_bash_script (string script_text){
				
		/* Creates a temporary bash script with given commands 
		 * Returns the script file path */
		
		var sh = "";
		sh += "#!/bin/bash\n";
		sh += script_text;

		string script_path = get_temp_file_path() + ".sh";

		if (write_file (script_path, sh)){  // create file
			chmod (script_path, "u+x");      // set execute permission
			return script_path;
		}
		else{
			return null;
		}
	}
	
	public string get_temp_file_path(){
				
		/* Generates temporary file path */
		
		return TEMP_DIR + "/" + timestamp2() + (new Rand()).next_int().to_string();
	}
	
	public int execute_command_script_sync (string script, out string std_out, out string std_err){
				
		/* Executes commands synchronously
		 * Returns exit code, output messages and error messages.
		 * Commands are written to a temporary bash script and executed. */
		
		string path = create_temp_bash_script(script);

		try {
			
			string[] argv = new string[1];
			argv[0] = path;
		
			int exit_code;
			
			Process.spawn_sync (
			    TEMP_DIR, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,   // child_setup
			    out std_out,
			    out std_err,
			    out exit_code
			    );
			    
			return exit_code;
		}
		catch (Error e){
	        log_error (e.message);
	        return -1;
	    }
	}
	
	public bool execute_command_script_in_terminal_sync (string script){
				
		/* Executes a command script in a terminal window */
		//TODO: Remove this
		
		try {
			
			string[] argv = new string[3];
			argv[0] = "x-terminal-emulator";
			argv[1] = "-e";
			argv[2] = script;
		
			Process.spawn_sync (
			    TEMP_DIR, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null   // child_setup
			    );
			    
			return true;
		}
		catch (Error e){
	        log_error (e.message);
	        return false;
	    }
	}

	public int execute_bash_script_fullscreen_sync (string script_file){
			
		/* Executes a bash script synchronously.
		 * Script is executed in a fullscreen terminal window */
		
		string path;
		
		path = get_cmd_path ("xfce4-terminal");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("xfce4-terminal --fullscreen -e \"%s\"".printf(script_file));
		}
		
		path = get_cmd_path ("gnome-terminal");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("gnome-terminal --full-screen -e \"%s\"".printf(script_file));
		}
		
		path = get_cmd_path ("xterm");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("xterm --fullscreen -e \"%s\"".printf(script_file));
		}
		
		//default terminal - unknown, normal window
		path = get_cmd_path ("x-terminal-emulator");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("x-terminal-emulator -e \"%s\"".printf(script_file));
		}
		
		return -1;
	}
	
	public int execute_bash_script_sync (string script_file){
			
		/* Executes a bash script synchronously in the default terminal window */
		
		string path = get_cmd_path ("x-terminal-emulator");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("x-terminal-emulator -e \"%s\"".printf(script_file));
		}
		
		return -1;
	}
	
	public string get_cmd_path (string cmd){
				
		/* Returns the full path to a command */
		
		try {
			int exitCode; 
			string stdout, stderr;
			Process.spawn_command_line_sync("which " + cmd, out stdout, out stderr, out exitCode);
	        return stdout;
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}

	public int get_pid_by_name (string name){
				
		/* Get the process ID for a process with given name */
		
		try{
			string output = "";
			Process.spawn_command_line_sync("pidof \"%s\"".printf(name), out output);
			if (output != null){
				string[] arr = output.split ("\n");
				if (arr.length > 0){
					return int.parse (arr[0]);
				}
			}
		} 
		catch (Error e) { 
			log_error (e.message); 
		}
		
		return -1;
	}

	public bool process_is_running(long pid){
		/* Checks if given process is running */
		
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		try{
			cmd = "ps --pid %ld".printf(pid);
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out ret_val);
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
		
		return (ret_val == 0);
	}

	public int[] get_process_children (Pid parentPid){
				
		/* Returns the list of child processes spawned by given process */
		
		string output;
		
		try {
			Process.spawn_command_line_sync("ps --ppid %d".printf(parentPid), out output);
		}
		catch(Error e){
	        log_error (e.message);
	    }
			
		int pid;
		int[] procList = {};
		string[] arr;
		
		foreach (string line in output.split ("\n")){
			arr = line.strip().split (" ");
			if (arr.length < 1) { continue; }
			
			pid = 0;
			pid = int.parse (arr[0]);
			
			if (pid != 0){
				procList += pid;
			}
		}
		return procList;
	}
	
	
	public void process_kill(Pid process_pid, bool killChildren = true){
				
		/* Kills specified process and its children (optional) */
		
		int[] child_pids = get_process_children (process_pid);
		Posix.kill (process_pid, 15);
		
		if (killChildren){
			Pid childPid;
			foreach (long pid in child_pids){
				childPid = (Pid) pid;
				Posix.kill (childPid, 15);
			}
		}
	}
	
	public int process_pause (Pid procID){
				
		/* Pause/Freeze a process */
		
		return execute_command_sync ("kill -STOP %d".printf(procID));
	}
	
	public int process_resume (Pid procID){
				
		/* Resume/Un-freeze a process*/
		
		return execute_command_sync ("kill -CONT %d".printf(procID));
	}

	public void command_kill(string cmd_name, string cmd){
				
		/* Kills a specific command */

		string txt = execute_command_sync_get_output ("ps w -C %s".printf(cmd_name));
		//use 'ps ew -C conky' for all users
		
		string pid = "";
		foreach(string line in txt.split("\n")){
			if (line.index_of(cmd) != -1){
				pid = line.strip().split(" ")[0];
				Posix.kill ((Pid) int.parse(pid), 15);
				log_debug(_("Stopped") + ": [PID=" + pid + "] ");
			}
		}
	}
	
	
	public void process_set_priority (Pid procID, int prio){
				
		/* Set process priority */
		
		if (Posix.getpriority (Posix.PRIO_PROCESS, procID) != prio)
			Posix.setpriority (Posix.PRIO_PROCESS, procID, prio);
	}
	
	public int process_get_priority (Pid procID){
				
		/* Get process priority */
		
		return Posix.getpriority (Posix.PRIO_PROCESS, procID);
	}
	
	public void process_set_priority_normal (Pid procID){
				
		/* Set normal priority for process */
		
		process_set_priority (procID, 0);
	}
	
	public void process_set_priority_low (Pid procID){
				
		/* Set low priority for process */
		
		process_set_priority (procID, 5);
	}
	

	public bool user_is_admin (){
				
		/* Check if current application is running with admin priviledges */
		
		try{
			// create a process
			string[] argv = { "sleep", "10" };
			Pid procId;
			Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out procId); 
			
			// try changing the priority
			Posix.setpriority (Posix.PRIO_PROCESS, procId, -5);
			
			// check if priority was changed successfully
			if (Posix.getpriority (Posix.PRIO_PROCESS, procId) == -5)
				return true;
			else
				return false;
		} 
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}

	public string get_user_login(){
		/* 
		Returns Login ID of current user.
		If running as 'sudo' it will return Login ID of the actual user.
		*/

		string cmd = "echo ${SUDO_USER:-$(whoami)}";
		string std_out;
		string std_err;
		int ret_val;
		ret_val = execute_command_script_sync(cmd, out std_out, out std_err);
		
		string user_name;
		if ((std_out == null) || (std_out.length == 0)){
			user_name = "root";
		}
		else{
			user_name = std_out.strip();
		}
		
		return user_name;
	}

	public int get_user_id(string user_login){
		/* 
		Returns UID of specified user.
		*/
		
		int uid = -1;
		string cmd = "id %s -u".printf(user_login);
		string txt = execute_command_sync_get_output(cmd);
		if ((txt != null) && (txt.length > 0)){
			uid = int.parse(txt);
		}
		
		return uid;
	}
	
	
	public string get_app_path (){
				
		/* Get path of current process */
		
		try{
			return GLib.FileUtils.read_link ("/proc/self/exe");	
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
	
	public string get_app_dir (){
				
		/* Get parent directory of current process */
		
		try{
			return (File.new_for_path (GLib.FileUtils.read_link ("/proc/self/exe"))).get_parent ().get_path ();	
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}

}

namespace TeeJee.GtkHelper{
	
	using Gtk;
	
	public void gtk_do_events (){
				
		/* Do pending events */
		
		while(Gtk.events_pending ())
			Gtk.main_iteration ();
	}

	public void gtk_set_busy (bool busy, Gtk.Window win) {
				
		/* Show or hide busy cursor on window */
		
		Gdk.Cursor? cursor = null;

		if (busy){
			cursor = new Gdk.Cursor(Gdk.CursorType.WATCH);
		}
		else{
			cursor = new Gdk.Cursor(Gdk.CursorType.ARROW);
		}
		
		var window = win.get_window ();
		
		if (window != null) {
			window.set_cursor (cursor);
		}
		
		gtk_do_events ();
	}
	
	public void gtk_messagebox(string title, string message, Gtk.Window? parent_win, bool is_error = false){
				
		/* Shows a simple message box */

		Gtk.MessageType type = Gtk.MessageType.INFO;
		if (is_error){
			type = Gtk.MessageType.ERROR;
		}
		else{
			type = Gtk.MessageType.INFO;
		}
		
		var dlg = new Gtk.MessageDialog.with_markup(null, Gtk.DialogFlags.MODAL, type, Gtk.ButtonsType.OK, message);
		dlg.title = title;
		dlg.set_default_size (200, -1);
		if (parent_win != null){
			dlg.set_transient_for(parent_win);
			dlg.set_modal(true);
		}
		dlg.run();
		dlg.destroy();
	}
	
	public bool gtk_combobox_set_value (ComboBox combo, int index, string val){
		
		/* Conveniance function to set combobox value */
		
		TreeIter iter;
		string comboVal;
		TreeModel model = (TreeModel) combo.model;
		
		bool iterExists = model.get_iter_first (out iter);
		while (iterExists){
			model.get(iter, 1, out comboVal);
			if (comboVal == val){
				combo.set_active_iter(iter);
				return true;
			}
			iterExists = model.iter_next (ref iter);
		} 
		
		return false;
	}
	
	public string gtk_combobox_get_value (ComboBox combo, int index, string default_value){
		
		/* Conveniance function to get combobox value */
		
		if (combo.model == null) { return default_value; }
		if (combo.active < 0) { return default_value; }
		
		TreeIter iter;
		string val = "";
		combo.get_active_iter (out iter);
		TreeModel model = (TreeModel) combo.model;
		model.get(iter, index, out val);
			
		return val;
	}

	public class CellRendererProgress2 : Gtk.CellRendererProgress{
		public override void render (Cairo.Context cr, Gtk.Widget widget, Gdk.Rectangle background_area, Gdk.Rectangle cell_area, Gtk.CellRendererState flags) {
			if (text == "--") 
				return;
				
			int diff = (int) ((cell_area.height - height)/2);
			
			// Apply the new height into the bar, and center vertically:
			Gdk.Rectangle new_area = Gdk.Rectangle() ;
			new_area.x = cell_area.x;
			new_area.y = cell_area.y + diff;
			new_area.width = width - 5;
			new_area.height = height;
			
			base.render(cr, widget, background_area, new_area, flags);
		}
	} 
	
	public Gdk.Pixbuf? get_app_icon(int icon_size, string format = ".png"){
		var img_icon = get_shared_icon(AppShortName, AppShortName + format,icon_size,"pixmaps");
		if (img_icon != null){
			return img_icon.pixbuf;
		}
		else{
			return null;
		}
	}
	
	public Gtk.Image? get_shared_icon(string icon_name, string fallback_icon_file_name, int icon_size, string icon_directory = AppShortName + "/images"){
		Gdk.Pixbuf pix_icon = null;
		Gtk.Image img_icon = null;
		
		try {
			Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
			pix_icon = icon_theme.load_icon (icon_name, icon_size, 0);
		} catch (Error e) {
			//log_error (e.message);
		}
		
		string fallback_icon_file_path = "/usr/share/%s/%s".printf(icon_directory, fallback_icon_file_name);
		
		if (pix_icon == null){ 
			try {
				pix_icon = new Gdk.Pixbuf.from_file_at_size (fallback_icon_file_path, icon_size, icon_size);
			} catch (Error e) {
				log_error (e.message);
			}
		}
		
		if (pix_icon == null){ 
			log_error (_("Missing Icon") + ": '%s', '%s'".printf(icon_name, fallback_icon_file_path));
		}
		else{
			img_icon = new Gtk.Image.from_pixbuf(pix_icon);
		}

		return img_icon; 
	}

}

namespace TeeJee.System{
	
	using TeeJee.ProcessManagement;
	using TeeJee.Logging;

	public double get_system_uptime_seconds(){
				
		/* Returns the system up-time in seconds */
		
		string cmd = "";
		string std_out;
		string std_err;
		int ret_val;
		
		try{
			cmd = "cat /proc/uptime";
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out ret_val);
			string uptime = std_out.split(" ")[0];
			double secs = double.parse(uptime);
			return secs;
		}
		catch(Error e){
			log_error (e.message);
			return 0;
		}
	}
	
	public string get_desktop_name(){
				
		/* Return the names of the current Desktop environment */
		
		int pid = -1;
		
		pid = get_pid_by_name("cinnamon");
		if (pid > 0){
			return "Cinnamon";
		}
		
		pid = get_pid_by_name("xfdesktop");
		if (pid > 0){
			return "Xfce";
		}

		pid = get_pid_by_name("lxsession");
		if (pid > 0){
			return "LXDE";
		}

		pid = get_pid_by_name("gnome-shell");
		if (pid > 0){
			return "Gnome";
		}
		
		pid = get_pid_by_name("wingpanel");
		if (pid > 0){
			return "Elementary";
		}
		
		pid = get_pid_by_name("unity-panel-service");
		if (pid > 0){
			return "Unity";
		}

		pid = get_pid_by_name("plasma-desktop");
		if (pid > 0){
			return "KDE";
		}
		
		return "Unknown";
	}

	public bool check_internet_connectivity(){
		int exit_code = -1;
		string std_err;
		string std_out;

		try {
			string cmd = "ping -c 1 google.com";
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out exit_code);
		}
		catch (Error e){
	        log_error (e.message);
	    }
		
	    return (exit_code == 0);
	}
	
	public bool shutdown (){
				
		/* Shutdown the system immediately */
		
		try{
			string[] argv = { "shutdown", "-h", "now" };
			Pid procId;
			Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out procId); 
			return true;
		} 
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}

	public bool xdg_open (string file){
		string path;
		path = get_cmd_path ("xdg-open");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("xdg-open \"" + file + "\"");
		}
		return false;
	}
	
	public bool exo_open_folder (string dir_path, bool xdg_open_try_first = true){
				
		/* Tries to open the given directory in a file manager */

		/*
		xdg-open is a desktop-independent tool for configuring the default applications of a user.
		Inside a desktop environment (e.g. GNOME, KDE, Xfce), xdg-open simply passes the arguments 
		to that desktop environment's file-opener application (gvfs-open, kde-open, exo-open, respectively).
		We will first try using xdg-open and then check for specific file managers if it fails. 
		*/
		
		string path;
		
		if (xdg_open_try_first){
			//try using xdg-open
			path = get_cmd_path ("xdg-open");
			if ((path != null)&&(path != "")){
				return execute_command_script_async ("xdg-open \"" + dir_path + "\"");
			}
		}
		
		path = get_cmd_path ("nemo");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("nemo \"" + dir_path + "\"");
		}
		
		path = get_cmd_path ("nautilus");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("nautilus \"" + dir_path + "\"");
		}
		
		path = get_cmd_path ("thunar");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("thunar \"" + dir_path + "\"");
		}

		path = get_cmd_path ("pantheon-files");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("pantheon-files \"" + dir_path + "\"");
		}
		
		path = get_cmd_path ("marlin");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("marlin \"" + dir_path + "\"");
		}

		if (xdg_open_try_first == false){
			//try using xdg-open
			path = get_cmd_path ("xdg-open");
			if ((path != null)&&(path != "")){
				return execute_command_script_async ("xdg-open \"" + dir_path + "\"");
			}
		}
		
		return false;
	}

	public bool exo_open_textfile (string txt){
				
		/* Tries to open the given text file in a text editor */
		
		string path;
		
		path = get_cmd_path ("exo-open");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("exo-open \"" + txt + "\"");
		}

		path = get_cmd_path ("gedit");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("gedit --new-document \"" + txt + "\"");
		}

		return false;
	}

	public bool exo_open_url (string url){
				
		/* Tries to open the given text file in a text editor */
		
		string path;
		
		path = get_cmd_path ("exo-open");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("exo-open \"" + url + "\"");
		}

		path = get_cmd_path ("firefox");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("firefox \"" + url + "\"");
		}

		path = get_cmd_path ("chromium-browser");
		if ((path != null)&&(path != "")){
			return execute_command_script_async ("chromium-browser \"" + url + "\"");
		}
		
		return false;
	}
	
	private DateTime dt_last_notification = null;
	private const int NOTIFICATION_INTERVAL = 3;
	
	public int notify_send (string title, string message, int durationMillis, string urgency, string dialog_type = "info"){
				
		/* Displays notification bubble on the desktop */

		int retVal = 0;
		
		switch (dialog_type){
			case "error":
			case "info":
			case "warning":
				//ok
				break;
			default:
				dialog_type = "info";
				break;
		}
		
		long seconds = 9999;
		if (dt_last_notification != null){
			DateTime dt_end = new DateTime.now_local();
			TimeSpan elapsed = dt_end.difference(dt_last_notification);
			seconds = (long)(elapsed * 1.0 / TimeSpan.SECOND);
		}
	
		if (seconds > NOTIFICATION_INTERVAL){
			string s = "notify-send -t %d -u %s -i %s \"%s\" \"%s\"".printf(durationMillis, urgency, "gtk-dialog-" + dialog_type, title, message);
			retVal = execute_command_sync (s);
			dt_last_notification = new DateTime.now_local();
		}

		return retVal;
	}
	
	public bool set_directory_ownership(string dir_name, string login_name){
		try {
			string cmd = "chown %s -R %s".printf(login_name, dir_name);
			int exit_code;
			Process.spawn_command_line_sync(cmd, null, null, out exit_code);
			
			if (exit_code == 0){
				//log_msg(_("Ownership changed to '%s' for files in directory '%s'").printf(login_name, dir_name));
				return true;
			}
			else{
				log_error(_("Failed to set ownership") + ": %s, %s".printf(login_name, dir_name));
				return false;
			}
		}
		catch (Error e){
			log_error (e.message);
			return false;
		}
	}

}

namespace TeeJee.Misc {
	
	/* Various utility functions */
	
	using Gtk;
	using TeeJee.Logging;
	using TeeJee.FileSystem;
	using TeeJee.ProcessManagement;
	
	public class DistInfo : GLib.Object{
				
		/* Class for storing information about linux distribution */
		
		public string dist_id = "";
		public string description = "";
		public string release = "";
		public string codename = "";
		
		public DistInfo(){
			dist_id = "";
			description = "";
			release = "";
			codename = "";
		}
		
		public string full_name(){
			if (dist_id == ""){
				return "";
			}
			else{
				string val = "";
				val += dist_id;
				val += (release.length > 0) ? " " + release : "";
				val += (codename.length > 0) ? " (" + codename + ")" : "";
				return val;
			}
		}
		
		public static DistInfo get_dist_info(string root_path){
				
			/* Returns information about the Linux distribution 
			 * installed at the given root path */
		
			DistInfo info = new DistInfo();
			
			string dist_file = root_path + "/etc/lsb-release";
			var f = File.new_for_path(dist_file);
			if (f.query_exists()){

				/*
					DISTRIB_ID=Ubuntu
					DISTRIB_RELEASE=13.04
					DISTRIB_CODENAME=raring
					DISTRIB_DESCRIPTION="Ubuntu 13.04"
				*/
				
				foreach(string line in read_file(dist_file).split("\n")){
					
					if (line.split("=").length != 2){ continue; }
					
					string key = line.split("=")[0].strip();
					string val = line.split("=")[1].strip();
					
					if (val.has_prefix("\"")){
						val = val[1:val.length];
					}
					
					if (val.has_suffix("\"")){
						val = val[0:val.length-1];
					}
					
					switch (key){
						case "DISTRIB_ID":
							info.dist_id = val;
							break;
						case "DISTRIB_RELEASE":
							info.release = val;
							break;
						case "DISTRIB_CODENAME":
							info.codename = val;
							break;
						case "DISTRIB_DESCRIPTION":
							info.description = val;
							break;
					}
				}
			}
			else{
				
				dist_file = root_path + "/etc/os-release";
				f = File.new_for_path(dist_file);
				if (f.query_exists()){
					
					/*
						NAME="Ubuntu"
						VERSION="13.04, Raring Ringtail"
						ID=ubuntu
						ID_LIKE=debian
						PRETTY_NAME="Ubuntu 13.04"
						VERSION_ID="13.04"
						HOME_URL="http://www.ubuntu.com/"
						SUPPORT_URL="http://help.ubuntu.com/"
						BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
					*/
					
					foreach(string line in read_file(dist_file).split("\n")){
					
						if (line.split("=").length != 2){ continue; }
						
						string key = line.split("=")[0].strip();
						string val = line.split("=")[1].strip();
						
						switch (key){
							case "ID":
								info.dist_id = val;
								break;
							case "VERSION_ID":
								info.release = val;
								break;
							//case "DISTRIB_CODENAME":
								//info.codename = val;
								//break;
							case "PRETTY_NAME":
								info.description = val;
								break;
						}
					}
				}
			}

			return info;
		}
		
	}

	public static Gdk.RGBA hex_to_rgba (string hex_color){
				
		/* Converts the color in hex to RGBA */
		
		string hex = hex_color.strip().down();
		if (hex.has_prefix("#") == false){
			hex = "#" + hex;
		}
		
		Gdk.RGBA color = Gdk.RGBA();
		if(color.parse(hex) == false){
			color.parse("#000000");
		}
		color.alpha = 255;
		
		return color;
	}
	
	public static string rgba_to_hex (Gdk.RGBA color, bool alpha = false, bool prefix_hash = true){
				
		/* Converts the color in RGBA to hex */
		
		string hex = "";
		
		if (alpha){
			hex = "%02x%02x%02x%02x".printf((uint)(Math.round(color.red*255)),
									(uint)(Math.round(color.green*255)),
									(uint)(Math.round(color.blue*255)),
									(uint)(Math.round(color.alpha*255)))
									.up();
		}
		else {														
			hex = "%02x%02x%02x".printf((uint)(Math.round(color.red*255)),
									(uint)(Math.round(color.green*255)),
									(uint)(Math.round(color.blue*255)))
									.up();
		}	
		
		if (prefix_hash){
			hex = "#" + hex;
		}	
		
		return hex;													
	}

	public string timestamp2 (){
				
		/* Returns a numeric timestamp string */
		
		return "%ld".printf((long) time_t ());
	}
	
	public string timestamp (){	
			
		/* Returns a formatted timestamp string */
		
		Time t = Time.local (time_t ());
		return t.format ("%H:%M:%S");
	}

	public string timestamp3 (){	
			
		/* Returns a formatted timestamp string */
		
		Time t = Time.local (time_t ());
		return t.format ("%Y-%d-%m_%H-%M-%S");
	}
	
	public string format_file_size (int64 size){
				
		/* Format file size in MB */
		
		return "%0.1f MB".printf (size / (1024.0 * 1024));
	}
	
	public string format_duration (long millis){
				
		/* Converts time in milliseconds to format '00:00:00.0' */
		
	    double time = millis / 1000.0; // time in seconds

	    double hr = Math.floor(time / (60.0 * 60));
	    time = time - (hr * 60 * 60);
	    double min = Math.floor(time / 60.0);
	    time = time - (min * 60);
	    double sec = Math.floor(time);
	    
        return "%02.0lf:%02.0lf:%02.0lf".printf (hr, min, sec);
	}
	
	public double parse_time (string time){
				
		/* Converts time in format '00:00:00.0' to milliseconds */
		
		string[] arr = time.split (":");
		double millis = 0;
		if (arr.length >= 3){
			millis += double.parse(arr[0]) * 60 * 60;
			millis += double.parse(arr[1]) * 60;
			millis += double.parse(arr[2]);
		}
		return millis;
	}
	
	public string escape_html(string html){
		return html
		.replace("&","&amp;")
		.replace("\"","&quot;")
		//.replace(" ","&nbsp;") //pango markup throws an error with &nbsp;
		.replace("<","&lt;")
		.replace(">","&gt;")
		;
	}
	
	public string unescape_html(string html){
		return html
		.replace("&amp;","&")
		.replace("&quot;","\"")
		//.replace("&nbsp;"," ") //pango markup throws an error with &nbsp;
		.replace("&lt;","<")
		.replace("&gt;",">")
		;
	}
	
	public string uri_encode(string unescaped_string){
		return GLib.Uri.escape_string(unescaped_string);
	}
	
	public string uri_decode(string escaped_string){
		return GLib.Uri.unescape_string(escaped_string);
	}
}

