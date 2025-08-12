/*
 * MainWindow.vala
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

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public class MainWindow : Window {

	private Image img_preview;
	private Box vbox_main;
	private Box vbox_status;
	private Box hbox_widget;
	private TreeView tv_widget;
	private ScrolledWindow sw_widget;
	private Button btn_add_theme;
	private ToggleButton btn_show_widgets;
	private ToggleButton btn_show_themes;
	private ToggleButton btn_preview;
	private ToggleButton btn_list;
	private Gtk.Paned pane;
	private Label lblSaveThemeSeparator;
	private Label lblFilter;
	private Entry txtFilter;
	private TreeModelFilter filterThemes;
	
	//toolbar
	private Toolbar toolbar;
	private ToolButton btn_prev;
	private ToolButton btn_next;
	private ToolButton btn_start;
	private ToolButton btn_start_terminal;
	private ToolButton btn_stop;
	private ToolButton btn_edit;
	private ToolButton btn_edit_gui;
	private ToolButton btn_open_dir;
	private ToolButton btn_scan;
	private ToolButton btn_generate_preview;
	private ToolButton btn_kill_all;
	private ToolButton btn_import_themes;
	private ToolButton btn_settings;
	private ToolButton btn_donate;
	private ToolButton btn_about;
	
	//status
	private Box hbox_progressbar;
	private ProgressBar progressbar;
	private Label lbl_status;
	private Button btn_cancel_action;
	private ScrolledWindow sw_preview;
	private EventBox ebox_preview;
	
	//credits
	private Box hbox_credits;
	private Label lbl_credits;
	private Label lbl_source;
	private LinkButton lbtn_source;
	
	//window dimensions
	private bool is_running;
	private bool is_aborted;
	private ConkyRC current_rc;
	private uint timer_init;
	private Gee.ArrayList<ConkyRC> rclist_generate;

	private const Gtk.TargetEntry[] targets = {
		{ "text/uri-list", 0, 0}
	};
	
	public MainWindow() {
		title = AppName + " v" + AppVersion;
        window_position = WindowPosition.CENTER;
        modal = true;
        set_default_size(App.window_width, App.window_height);
		icon = get_app_icon(16);

		Gtk.drag_dest_set (this,Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
		drag_data_received.connect(on_drag_data_received);
		
		string tt = "";
		
		//vbox_main
        vbox_main = new Box (Orientation.VERTICAL, 6);
		add(vbox_main);
		
		//toolbar
        init_toolbar();
        
        //hbox_widget
        hbox_widget = new Box (Orientation.HORIZONTAL, 6);
        hbox_widget.margin_left = 3;
        hbox_widget.margin_right = 3;
		vbox_main.add(hbox_widget);

		//lbl_type
		Label lbl_type = new Label (_("Browse:"));
		hbox_widget.add(lbl_type);
		
		//btn_show_widgets
		btn_show_widgets = new ToggleButton.with_label(_("Widgets"));
		hbox_widget.pack_start (btn_show_widgets, false, true, 0);
		
		//btn_show_themes
		btn_show_themes = new ToggleButton.with_label(_("Themes"));
		hbox_widget.pack_start (btn_show_themes, false, true, 0);
		
		btn_show_widgets.toggled.connect(()=>{
			if (btn_show_widgets.active){
				btn_show_themes.active = false;
				btn_add_theme.visible = false;
				btn_generate_preview.visible = true;
				
				lblSaveThemeSeparator.visible = btn_add_theme.visible;
				txtFilter.text = "";
				reload_themes();
			}
		});
		
		btn_show_themes.toggled.connect(()=>{
			if (btn_show_themes.active){
				btn_show_widgets.active = false;
				btn_add_theme.visible = true;
				btn_generate_preview.visible = false;
				
				lblSaveThemeSeparator.visible = btn_add_theme.visible;
				txtFilter.text = "";
				reload_themes();
			}
		});

		//separator
		hbox_widget.add(new Label(" | "));
		
		//add theme button
		btn_add_theme = new Button.with_label(_("Save Theme"));
		btn_add_theme.set_size_request(10,-1);
		btn_add_theme.set_image(new Image.from_stock ("gtk-add", IconSize.MENU));
		btn_add_theme.no_show_all = true;
		btn_add_theme.set_tooltip_text(_("Save running widgets and current desktop wallpaper as new theme"));
		hbox_widget.pack_start (btn_add_theme, false, true, 0);
		
		btn_add_theme.clicked.connect(btn_add_theme_clicked);
		
		//separator
		lblSaveThemeSeparator = new Label(" | ");
		hbox_widget.add(lblSaveThemeSeparator);
		
		//filter
		lblFilter = new Label(_("Filter"));
		hbox_widget.add(lblFilter);
		
		txtFilter = new Entry();
		hbox_widget.pack_start (txtFilter, true, true, 0);
		txtFilter.changed.connect(()=>{ 
			filterThemes.refilter(); 
			show_preview(selected_item()); 
		});
		
		tt = _("Enter name or path to filter.\nEnter '0' to list running widgets");
		lblFilter.set_tooltip_text(tt);
		txtFilter.set_tooltip_text(tt);
		
		//lbl_expand
		Label lbl_expand = new Label ("");
		lbl_expand.hexpand = true;
		hbox_widget.add(lbl_expand);
		
		//btn_preview
		btn_preview = new ToggleButton.with_label(_("Preview"));
		btn_preview.active = App.show_preview;
		btn_preview.set_tooltip_text(_("Toggle Preview"));
		hbox_widget.pack_start (btn_preview, false, true, 0);

		//btn_list
		btn_list = new ToggleButton.with_label(_("List"));
		btn_list.active = App.show_list;
		btn_list.set_tooltip_text(_("Toggle List"));
		hbox_widget.pack_start (btn_list, false, true, 0);

		btn_preview.toggled.connect(btn_preview_toggled);
		btn_list.toggled.connect(btn_list_toggled);
		
		//status
        vbox_status = new Box (Orientation.VERTICAL, 3);
        vbox_status.no_show_all = true;
        vbox_status.margin = 3;
		vbox_main.add(vbox_status);

		lbl_status = new Label ("");
		lbl_status.halign = Align.START;
		lbl_status.max_width_chars = 100;
		lbl_status.ellipsize = Pango.EllipsizeMode.END;
		vbox_status.pack_start (lbl_status, false, true, 0);
		
		//progressbar
        hbox_progressbar = new Box (Orientation.HORIZONTAL, 6);
		vbox_status.add(hbox_progressbar);

		progressbar = new ProgressBar();
		progressbar.no_show_all = true;
		progressbar.set_size_request(-1,20);
		hbox_progressbar.pack_start (progressbar, true, true, 0);

		btn_cancel_action = new Gtk.Button.with_label (" " + _("Stop") + " ");
		btn_cancel_action.set_size_request(50,-1);
		btn_cancel_action.set_tooltip_text(_("Stop"));
		hbox_progressbar.pack_start (btn_cancel_action, false, false, 0);
		
		pane = new Gtk.Paned (Gtk.Orientation.VERTICAL);
		pane.position = App.pane_position;
		vbox_main.add(pane);
		
		pane.notify["position"].connect (() => {
			App.pane_position = pane.position;
		});

		//credits
        hbox_credits = new Box (Orientation.HORIZONTAL, 3);
        //hbox_credits.margin = 3;
		vbox_main.add(hbox_credits);

		lbl_source = new Label (_("Source") + ":");
		lbl_source.halign = Align.START;
		lbl_source.max_width_chars = 100;
		lbl_source.ellipsize = Pango.EllipsizeMode.END;
		hbox_credits.pack_start (lbl_source, false, true, 0);
		
		lbtn_source = new LinkButton("");
		lbtn_source.halign = Align.START;
		hbox_credits.pack_start (lbtn_source, true, true, 0);
		
		lbl_credits = new Label (_("Credits"));
		lbl_credits.halign = Align.START;
		lbl_credits.max_width_chars = 100;
		lbl_credits.ellipsize = Pango.EllipsizeMode.END;
		//hbox_credits.pack_end (lbl_credits, false, true, 0);
		
		//list_view
		init_list_view();
		
		//preview_area
		init_preview_area();

		//keyboard_shortcuts
		init_keyboard_shortcuts();

		timer_init = Timeout.add(100, init_delayed);
	}
	
	private void init_toolbar(){
        //toolbar
		toolbar = new Gtk.Toolbar ();
		toolbar.toolbar_style = ToolbarStyle.BOTH_HORIZ;
		toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		toolbar.set_icon_size(IconSize.LARGE_TOOLBAR);
		//toolbar.set_size_request(-1,48);
		vbox_main.add(toolbar);

		//btn_prev
		btn_prev = new Gtk.ToolButton.from_stock ("gtk-go-back");
		btn_prev.is_important = false;
		btn_prev.label = _("Previous");
		btn_prev.set_tooltip_text (_("Previous Widget"));
//        toolbar.add(btn_prev);

        btn_prev.clicked.connect(btn_prev_clicked);

		//btn_next
		btn_next = new Gtk.ToolButton.from_stock ("gtk-go-forward");
		btn_next.is_important = false;
		btn_next.label = _("Next");
		btn_next.set_tooltip_text (_("Next Widget"));
//        toolbar.add(btn_next);

        btn_next.clicked.connect(btn_next_clicked);

		//btn_start terminal
		btn_start_terminal = new Gtk.ToolButton.from_stock ("gtk-media-play");
		btn_start_terminal.is_important = false;
		btn_start_terminal.icon_widget = get_shared_icon("utilities-terminal","utilities-terminal.png",32);
		btn_start_terminal.label = _("Terminal Start");
		btn_start_terminal.set_tooltip_text (_("Start/Restart Widget in Terminal"));
        toolbar.add(btn_start_terminal);

        btn_start_terminal.clicked.connect(btn_start_terminal_clicked);

		//btn_start
		btn_start = new Gtk.ToolButton.from_stock ("gtk-media-play");
		btn_start.is_important = false;
		btn_start.label = _("Start");
		btn_start.set_tooltip_text (_("Start/Restart Widget"));
        toolbar.add(btn_start);

        btn_start.clicked.connect(btn_start_clicked);

		//btn_stop
		btn_stop = new Gtk.ToolButton.from_stock ("gtk-media-stop");
		btn_stop.is_important = false;
		btn_stop.label = _("Start");
		btn_stop.set_tooltip_text (_("Stop Widget"));
        toolbar.add(btn_stop);

        btn_stop.clicked.connect(btn_stop_clicked);
        
        //separator1
		var separator1 = new Gtk.SeparatorToolItem();
		separator1.set_draw(true);
		toolbar.add(separator1);
		
		//btn_edit_gui
		btn_edit_gui = new Gtk.ToolButton.from_stock ("gtk-preferences");
		btn_edit_gui.is_important = false;
		btn_edit_gui.label = _("Edit");
		btn_edit_gui.set_tooltip_text (_("Edit Widget"));
        toolbar.add(btn_edit_gui);

        btn_edit_gui.clicked.connect(btn_edit_gui_clicked);
        
		//btn_edit
		btn_edit = new Gtk.ToolButton.from_stock ("gtk-edit");
		btn_edit.is_important = false;
		btn_edit.label = _("Manual Edit");
		btn_edit.set_tooltip_text (_("Edit file manually in a text editor"));
        toolbar.add(btn_edit);

        btn_edit.clicked.connect(btn_edit_clicked);

		//btn_open_dir
		btn_open_dir = new Gtk.ToolButton.from_stock ("gtk-directory");
		btn_open_dir.is_important = false;
		btn_open_dir.label = _("Open Folder");
		btn_open_dir.set_tooltip_text (_("Open Theme Folder"));
        toolbar.add(btn_open_dir);

        btn_open_dir.clicked.connect(btn_open_dir_clicked);

        //separator1
		var separator2 = new Gtk.SeparatorToolItem();
		separator2.set_draw(true);
		toolbar.add(separator2);

		//btn_scan
		btn_scan = new Gtk.ToolButton.from_stock ("gtk-refresh");
		btn_scan.is_important = false;
		btn_scan.label = _("Refresh");
		btn_scan.set_tooltip_text (_("Search for new themes"));
        toolbar.add(btn_scan);

        btn_scan.clicked.connect(btn_scan_clicked);
        
		//btn_generate_preview
		btn_generate_preview = new Gtk.ToolButton.from_stock ("gtk-missing-image");
		btn_generate_preview.is_important = false;
		btn_generate_preview.label = _("Generate Preview");
		btn_generate_preview.set_tooltip_text (_("Generate preview images"));
        toolbar.add(btn_generate_preview);

		btn_generate_preview.icon_widget = get_shared_icon("","image-generate24x24.png",24);
		
        btn_generate_preview.clicked.connect(btn_generate_preview_clicked);

		//btn_kill_all
		btn_kill_all = new Gtk.ToolButton.from_stock ("gtk-cancel");
		btn_kill_all.is_important = false;
		btn_kill_all.label = _("Stop All Widgets");
		btn_kill_all.set_tooltip_text (_("Stop all running widgets"));
        toolbar.add(btn_kill_all);

        btn_kill_all.clicked.connect(btn_kill_all_clicked);

		//btn_import_themes
		btn_import_themes = new Gtk.ToolButton.from_stock ("gtk-open");
		btn_import_themes.is_important = false;
		btn_import_themes.label = _("Import");
		btn_import_themes.set_tooltip_text (_("Import Theme Pack (*.cmtp.7z) or various archive type"));
        toolbar.add(btn_import_themes);

        btn_import_themes.clicked.connect(btn_import_themes_clicked);
        
        //separator
		var separator = new Gtk.SeparatorToolItem();
		separator.set_draw(false);
		separator.set_expand(true);
		toolbar.add(separator);
		
		//btn_settings
		btn_settings = new Gtk.ToolButton.from_stock ("gtk-preferences");
		btn_settings.is_important = false;
		btn_settings.label = _("Settings");
		btn_settings.set_tooltip_text (_("Application Settings"));
        toolbar.add(btn_settings);

        btn_settings.clicked.connect(btn_settings_clicked);

        //btn_donate
		btn_donate = new Gtk.ToolButton.from_stock ("gtk-dialog-info");
		btn_donate.is_important = false;
		btn_donate.icon_widget = get_shared_icon("donate","donate.svg",32);
		btn_donate.label = _("Funding");
		btn_donate.set_tooltip_text (_("Funding Support"));
        toolbar.add(btn_donate);

        btn_donate.clicked.connect(() => { show_donation_window(false); });
        
        //btn_about
		btn_about = new Gtk.ToolButton.from_stock ("gtk-about");
		btn_about.is_important = false;
		btn_about.label = _("About");
		btn_about.set_tooltip_text (_("About"));
        toolbar.add(btn_about);

        btn_about.clicked.connect(btn_about_clicked);
	}
	
	private void init_list_view(){
		//list view
		tv_widget = new TreeView();
		tv_widget.get_selection().mode = SelectionMode.SINGLE;
		tv_widget.headers_visible = false;
		tv_widget.set_rules_hint (true);
		
		sw_widget = new ScrolledWindow(null, null);
		sw_widget.set_shadow_type (ShadowType.ETCHED_IN);
		sw_widget.add (tv_widget);
		sw_widget.expand = true;
		pane.pack1(sw_widget,true,true);

		TreeViewColumn col_widget = new TreeViewColumn();
		col_widget.title = " " + _("Enable") + " ";
		tv_widget.append_column(col_widget);
		
		CellRendererToggle cell_widget_enable = new CellRendererToggle ();
		cell_widget_enable.activatable = true;
		col_widget.pack_start (cell_widget_enable, false);
		
		col_widget.set_cell_data_func (cell_widget_enable, (cell_layout, cell, model, iter)=>{
			bool val;
			model.get (iter, 0, out val, -1);
			(cell as Gtk.CellRendererToggle).active = val;
		});
		
		cell_widget_enable.toggled.connect (cell_widget_enable_toggled);

		CellRendererText cell_widget_name = new CellRendererText ();
		col_widget.pack_start (cell_widget_name, false);
		
		col_widget.set_cell_data_func (cell_widget_name, (cell_layout, cell, model, iter)=>{
			ConkyRC rc;
			model.get (iter, 1, out rc, -1);
			(cell as Gtk.CellRendererText).text = rc.name;
		});
		
		TreeSelection sel = tv_widget.get_selection();
		sel.changed.connect(()=>{
			show_preview(selected_item());
		});
	}
	
	private void init_preview_area(){
		sw_preview = new ScrolledWindow(null, null);
		sw_preview.set_shadow_type(ShadowType.ETCHED_IN);
		sw_preview.expand = true;
		pane.pack2(sw_preview,true,true);
		
		string tt = _("Use the keyboard arrow keys to browse.\nPress ENTER to start and stop.");
		sw_preview.set_tooltip_text(tt);

		img_preview = new Image();
		ebox_preview = new EventBox();
		ebox_preview.add(img_preview);
		sw_preview.add_with_viewport(ebox_preview);
	}
	
	private void init_keyboard_shortcuts(){
		this.key_press_event.connect ((w, event) => {

			if (!toolbar.sensitive) { return false; }

			if ((event.keyval == 65361)||(event.keyval == 65362)) {
				btn_prev_clicked();
				return false;
			}
			else if ((event.keyval == 65363)||(event.keyval == 65364)){
				btn_next_clicked();
				return false;
			}
			else if (event.keyval == 65293) {
				if (selected_item().enabled){
					btn_stop_clicked();
				}
				else{
					btn_start_clicked();
				}
				return true;
			}

			return false;
		});
	}
	
	private bool init_delayed(){
		Source.remove(timer_init);
		
		//call handlers
		btn_preview_toggled();
		btn_list_toggled();
		btn_show_widgets.active = true;

		btn_scan_clicked();
		
		return true;
	}
	
	private void reload_themes(){
		
		txtFilter.text = "";
		
		double vpos = sw_widget.vadjustment.value;
		
		tv_widget_refresh();
		show_preview(selected_item());
		
		if (btn_preview.active){
			sw_preview.visible = true;
		}
		
		if (btn_list.active){
			sw_widget.visible = true;
		}

		sw_widget.vadjustment.value = vpos;
	}

	private void on_drag_data_received (Gdk.DragContext drag_context, int x, int y, Gtk.SelectionData data, uint info, uint time) {
        gtk_set_busy(true, this);
		gtk_do_events();
        
        SList<string> files = new SList<string>();
        foreach(string uri in data.get_uris()){
			string file = uri.replace("file://","").replace("file:/","");
			file = Uri.unescape_string(file);
			if ( file.has_suffix(".7z") || file.has_suffix(".bz2") || file.has_suffix(".gz") 
                || file.has_suffix(".xz") || file.has_suffix(".tar") || file.has_suffix(".zip") )
				files.append(file);
		}

		install_theme_packs(files);

        Gtk.drag_finish (drag_context, true, false, time);
    }
	
	//actions
	
	private void btn_preview_toggled(){
		App.show_preview = btn_preview.active;
		sw_preview.visible = App.show_preview;
		if ((!btn_list.active)&&(!btn_preview.active)){
			btn_list.active = true;
		}
	}

	private void btn_list_toggled(){
		App.show_list = btn_list.active;
		sw_widget.visible = App.show_list;
		if ((!btn_list.active)&&(!btn_preview.active)){
			btn_preview.active = true;
		}
	}

	private void btn_add_theme_clicked(){
		App.refresh_conkyrc_status();
		
		var dialog = new EditThemeWindow(null);
		dialog.set_transient_for (this);
		dialog.show_all();
		dialog.run();
		dialog.destroy();
		
		reload_themes();
	}
	
	private void btn_prev_clicked(){
		TreeModel model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter;
		
		if (selection.count_selected_rows() > 0){
			selection.get_selected(out model, out iter);

			if (model.iter_previous(ref iter)){
				selection.select_iter(iter);
			}
		}	

		show_preview(selected_item());
	}
	
	private void btn_next_clicked(){
		TreeModel model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter;

		if (selection.count_selected_rows() > 0){
			selection.get_selected(out model, out iter);

			if (model.iter_next(ref iter)){
				selection.select_iter(iter);
			}
		}	

		show_preview(selected_item());
	}

	private void btn_start_terminal_clicked(){
		TreeModel model;
		TreeStore store = (TreeStore) filterThemes.child_model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter, child_iter;
		ConkyConfigItem item;

		//check if selected
		if (selection.count_selected_rows() == 0){ return; }

		//get item
		selection.get_selected(out model, out iter);
		model.get(iter,1,out item,-1);

		//show busy icon
		gtk_set_busy(true, this);
		gtk_do_events();

		//start item
		item.terminal_start();
		show_preview(item);

		//hide busy icon
		gtk_set_busy(false, this);

		//uncheck other items
		if (item is ConkyTheme){
			TreeIter iter2;
			bool iterExists = model.get_iter_first (out iter2);
			while (iterExists){
				if (iter2 != iter){
					//uncheck
					filterThemes.convert_iter_to_child_iter(out child_iter, iter2);
					store.set(child_iter, 0, false);
				}
				iterExists = model.iter_next (ref iter2);
			}
		}

		//check item
		filterThemes.convert_iter_to_child_iter(out child_iter, iter);
		store.set(child_iter, 0, true, -1);
	}

	private void btn_start_clicked(){
		TreeModel model;
		TreeStore store = (TreeStore) filterThemes.child_model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter, child_iter;
		ConkyConfigItem item;

		//check if selected
		if (selection.count_selected_rows() == 0){ return; }

		//get item
		selection.get_selected(out model, out iter);
		model.get(iter,1,out item,-1);

		//show busy icon
		gtk_set_busy(true, this);
		gtk_do_events();
		
		//start item
		item.start();
		show_preview(item);

		//hide busy icon
		gtk_set_busy(false, this);
		
		//uncheck other items
		if (item is ConkyTheme){
			TreeIter iter2;
			bool iterExists = model.get_iter_first (out iter2);
			while (iterExists){
				if (iter2 != iter){
					//uncheck
					filterThemes.convert_iter_to_child_iter(out child_iter, iter2);
					store.set(child_iter, 0, false);
				}
				iterExists = model.iter_next (ref iter2);
			}
		}

		//check item
		filterThemes.convert_iter_to_child_iter(out child_iter, iter);
		store.set(child_iter, 0, true, -1);
	}
	
	private void btn_stop_clicked(){
		TreeModel model = (TreeModel) filterThemes;
		TreeStore store = (TreeStore) filterThemes.child_model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter, child_iter;
		ConkyConfigItem item;
		
		//check if selected
		if (selection.count_selected_rows() == 0){ return; }
		
		//get item
		selection.get_selected(out model, out iter);
		model.get(iter,1,out item,-1);

		//show busy icon
		gtk_set_busy(true, this);
		gtk_do_events();
		
		//stop
		item.stop();
		show_preview(item);

		//hide busy icon
		gtk_set_busy(false, this);
		
		//uncheck item
		filterThemes.convert_iter_to_child_iter(out child_iter, iter);
		store.set(child_iter, 0, false, -1);
	}
	
	private void btn_edit_gui_clicked(){
		ConkyConfigItem item = selected_item();
		
		if (item is ConkyRC){
			var dialog = new EditWidgetWindow((ConkyRC) item);
			dialog.set_transient_for(this);
			dialog.show_all();
			dialog.run();
			dialog.destroy();
		}
		else{
			App.refresh_conkyrc_status();
			
			var dialog = new EditThemeWindow((ConkyTheme)selected_item());
			dialog.set_transient_for (this);
			dialog.show_all();
			dialog.run();
			dialog.destroy();
		}
	}
	
	private void btn_edit_clicked(){
		ConkyConfigItem item = selected_item();
		/*if (item != null) { exo_open_textfile(item.path); };
        what is going on here, xdg-open should be sufficient. */
		if (item != null) { xdg_open(item.path); };
	}

	private void btn_open_dir_clicked(){
		ConkyConfigItem item = selected_item();
		if (item != null) { exo_open_folder(item.dir); };
	}
	
	private void btn_scan_clicked(){
		scan_themes();
	}

	private void btn_generate_preview_clicked(){
		//get options
		var dialog = new GeneratePreviewWindow();
		dialog.set_transient_for (this);
		dialog.show_all();
		dialog.optGenerateCurrent.sensitive = (selected_item() != null);
		dialog.optGenerateMissing.active = (selected_item() == null);
		
		int response = dialog.run();
		string action = dialog.action;
		dialog.destroy();
		
		//clear list
		rclist_generate = new Gee.ArrayList<ConkyRC>();
		
		//make list
		if (response == Gtk.ResponseType.OK){
			switch(action){
				case "current":
					rclist_generate.add((ConkyRC)selected_item());
					break;
				case "missing":
					foreach(ConkyRC rc in App.conkyrc_list){
						//check if image file is a "default" image
						string[] ext_list = {".png",".jpg",".jpeg"};
						foreach(string ext in ext_list){
							string image_name = "preview" + ext;
							if (rc.image_path.has_suffix(image_name)){ 
								rclist_generate.add(rc);
								continue;
							}
						}
						
						//check if image file is missing
						if (!file_exists(rc.image_path)){
							rclist_generate.add(rc);
						}
					}
					break;
				case "all":
					foreach(ConkyRC rc in App.conkyrc_list){
						rclist_generate.add(rc);
					}
					break;
			}
		}
		else{ 
			return; //cancel
		}

		progress_begin(_("Generating Previews") + "...");
		
		//change view
		bool show_preview = btn_preview.active;
		bool show_list = btn_list.active;
		btn_preview.active = true;
		btn_list.active = false;
		
		is_aborted = false;

		btn_cancel_action.clicked.connect(btn_cancel_action_generate_preview);
		
		try {
			is_running = true;
			Thread.create<void> (btn_generate_preview_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			gtk_do_events();
		}
				
		btn_cancel_action.clicked.disconnect(btn_cancel_action_generate_preview);
		
		progress_hide();
		
		//restore selected view
		btn_preview.active = show_preview;
		btn_list.active = show_list;
		
		//reload_themes();
	}
	
	private void btn_generate_preview_clicked_thread(){
		gtk_set_busy(true,this);
		
		generate_previews();
		is_running = false;
		
		gtk_set_busy(false,this);
	}
	
	private void generate_previews(){
		
		//save running widgets
		var running_list = new Gee.ArrayList<string>();
		foreach(ConkyRC rc in App.conkyrc_list){
			if (rc.enabled){
				running_list.add(rc.path);
			}
		}
		
		//kill running widgets
		App.kill_all_conky();
		
		int count_total = rclist_generate.size;
		int count = 0;
		
		foreach(ConkyRC rc in rclist_generate){
			
			if (is_aborted) { break; }
			
			current_rc = rc;
			rc.generate_preview();
			current_rc = null;

			count++;
			progressbar.fraction = count / (count_total * 1.0);

			show_preview(rc);
			
			lbl_status.label = _("Generating Previews") + " [%d OF %d]\n%s".printf(count, count_total, rc.name);
			gtk_do_events();
		}
		
		//start widgets that were running
		foreach(ConkyRC rc in App.conkyrc_list){
			if (running_list.contains(rc.path)){
				rc.start();
			}
		}
		
		//show previously selected widget
		show_preview(selected_item());
	}
	
	private void btn_cancel_action_scan(){
		App.load_themes_and_widgets_cancel();
	}
	
	private void btn_cancel_action_generate_preview(){
		is_aborted = true;
		App.kill_all_conky();
	}
	
	private void btn_kill_all_clicked(){
		App.kill_all_conky();
		
		TreeModel model = filterThemes;
		TreeStore store = (TreeStore) filterThemes.child_model;
		TreeIter iter;

		bool iterExists = model.get_iter_first (out iter);
		while (iterExists){
			store.set (iter, 0, false, -1);
			iterExists = model.iter_next (ref iter);
		}
	}

	private void btn_import_themes_clicked(){
		var dlgAddFiles = new Gtk.FileChooserDialog(_("Import") + " (cmtp.7z; 7z; gz; bz2; xz; tar; zip; etc.)", this, Gtk.FileChooserAction.OPEN,
							"gtk-cancel", Gtk.ResponseType.CANCEL,
							"gtk-open", Gtk.ResponseType.ACCEPT);
		dlgAddFiles.local_only = true;
 		dlgAddFiles.set_modal (true);
 		dlgAddFiles.set_select_multiple (true);
 		
		Gtk.FileFilter filter = new Gtk.FileFilter ();
		//dlgAddFiles.set_filter (filter);
		filter.add_pattern ("*.cmtp.7z");
		filter.add_pattern ("*.7z");
		filter.add_pattern ("*.tar.7z");
		filter.add_pattern ("*.gz");
		filter.add_pattern ("*.tar.gz");
		filter.add_pattern ("*.bz2");
		filter.add_pattern ("*.tar.bz2");
		filter.add_pattern ("*.xz");
		filter.add_pattern ("*.tar.xz");
		filter.add_pattern ("*.tar");
		filter.add_pattern ("*.zip");
        filter.set_name("Conky Manager Theme or various compressed archive");
		dlgAddFiles.add_filter (filter);
		
		//show the dialog and get list of files
		SList<string> files = null;
 		if (dlgAddFiles.run() == Gtk.ResponseType.ACCEPT){
			files = dlgAddFiles.get_filenames();
	 	}
		dlgAddFiles.destroy();
		
		if (files == null){
			return;
		}
		
		install_theme_packs(files);
	}
	
	private void install_theme_packs(SList<string> files){
		gtk_set_busy(true, this);
		gtk_do_events();
		
		bool ok = true;
		foreach (string file in files){
			if (file.has_suffix(".tar.7z") || file.has_suffix(".tar.bz2") || file.has_suffix(".tar.gz") 
                || file.has_suffix(".tar.xz") || file.has_suffix(".tar"))
				ok = ok && App.install_theme_pack(file, true);
            else
				ok = ok && App.install_theme_pack(file);
		}
		
		scan_themes();

		gtk_set_busy(false, this);
		
		if (ok){
			gtk_messagebox(_("Themes Imported"), _("Themes imported successfully"),this);
		}
		else{
			gtk_messagebox(_("Error"), _("Failed to import themes"),this);
		}
	}
	
	private void btn_settings_clicked(){
		var dialog = new SettingsWindow();
		dialog.set_transient_for(this);
		dialog.show_all();
		dialog.run();
		dialog.destroy();
	}

	public void show_donation_window(bool on_exit){
		var dialog = new DonationWindow();
		dialog.set_transient_for(this);
		dialog.show_all();
		dialog.run();
		dialog.destroy();
	}

	private void btn_about_clicked(){
		var dialog = new AboutWindow();
		dialog.set_transient_for (this);

		dialog.authors = {
			"Tony George:teejeetech@gmail.com",
			"Scott Caudle:zcotcaudle@gmail.com"
		};

		dialog.translators = {
			"yeji0407 (Korean):github.com/yeji0407",
			"freddii (German):github.com/freddii",
			"fehlix (French):github.com/fehlix",
			"tioguda (Portuguese - Brazil):github.com/tioguda",
			"Vistaus (Dutch):github.com/Vistaus",
			"gogo (Croatian):launchpad.net/~trebelnik-stefina",
			"Radek Otáhal (Czech):radek.otahal@email.cz"
		}; 
		
		dialog.third_party = {
			"Conky Manager is powered by the following tools and components. Please visit the links for more information.",
			"Conky by Brenden Matthews:http://conky.sourceforge.net/",
			"ImageMagick by ImageMagick Studio LLC:http://imagemagick.org/",
			"7-Zip by Igor Pavlov:http://www.7-zip.org/",
			"Themes by various authors from DeviantArt.com:http://www.deviantart.com/browse/all/customization/skins/?q=conky"
		}; 
		
		dialog.documenters = null; 
		dialog.artists = {
			"Morten Kjeldgaard"
		}; 
		
		dialog.donations = {
			"Adam Simmons",
			"Andre Strobach",
			"Dan Raymond",
			"Edwin Pallens",
			"Flaviu Dan",
			"Gus Chavez",
			"Jan Sandberg",
			"Jesse Avalos",
			"John Cruz",
			"Nicola Jelmorini",
			"Radek Otahal",
			"Raymond Shaffer",
			"Steven Dudek",
			"Steven Klausmeier",
			"Umut Baris Demir",
			"Will Hartley",
			"William Keller"
		};
		
		dialog.program_name = AppName;
		dialog.comments = _("Utility for managing Conky configuration files");
		dialog.copyright = "Copyright © 2014 Tony George (%s)".printf(AppAuthorEmail);
		dialog.copyright2 = "Copyright © 2018 Scott Caudle (%s)".printf(AppAuthorEmail2);
		dialog.version = AppVersion;
		dialog.logo = get_app_icon(128);

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.website = "http://teejeetech.in";
		dialog.website_label = "http://teejeetech.blogspot.in";
		dialog.website2 = "https://github.com/zcot/conky-manager2";
		dialog.website_label2 = "project on github";

		dialog.initialize();
		dialog.show_all();
	}
	
	private void show_preview(ConkyConfigItem? item){
		img_preview.pixbuf = null;
		
		if (item == null){
			img_preview.pixbuf = null;
			return;
		}
		
		int screen_width = Gdk.Screen.width();
		int screen_height = Gdk.Screen.height();

		if ((item.image_path.length > 0) && file_exists(item.image_path)){
			try{
				Gdk.Pixbuf px = new Gdk.Pixbuf.from_file(item.image_path);

				//scale down the image if it is very large
				if ((px.width > (screen_width * 1.5)) || (px.height > (screen_height * 1.5))){
					//scale down 50%
					int scaled_width = px.width / 2;
					int scaled_height = px.height / 2;
					px = new Gdk.Pixbuf.from_file_at_scale(item.image_path,scaled_width,scaled_height,true);
					img_preview.pixbuf = px;
				}
				else{
					img_preview.pixbuf = px;
				}
			}
			catch(Error e){
				log_error (e.message);
			}
		}
		else{
			img_preview.pixbuf = null;
		}
		
		if (item.url.length > 0){
			lbtn_source.uri = item.url;
			lbtn_source.label = item.url;
		}
		else{
			lbtn_source.uri = "";
			lbtn_source.label = _("N/A");
		}
		
		if (item.credits.length > 0){
			//lbl_credits.visible = true;
		}
		else{
			//lbl_credits.visible = false;
		}
	}

	private void scan_themes(){
		progress_begin(_("Searching directories..."));

		btn_cancel_action.clicked.connect(btn_cancel_action_scan);
		
		try {
			is_running = true;
			Thread.create<void> (scan_themes_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			progressbar.pulse();
			gtk_do_events();
		}
		
		btn_cancel_action.clicked.disconnect(btn_cancel_action_scan);
		
		progress_hide();

		reload_themes();
	}
	
	private void scan_themes_thread(){
		App.load_themes_and_widgets();
		reload_themes();
		is_running = false;
	}

	private void progress_begin(string message = ""){
		toolbar.sensitive = false;
		hbox_widget.visible = false;

		vbox_status.visible = true;
		lbl_status.visible = true;
		hbox_progressbar.visible = true;
		progressbar.visible = true;
		btn_cancel_action.visible = true;

		progressbar.fraction = 0.0;
		lbl_status.label = message;
		
		hbox_credits.visible = false;
		
		//gtk_set_busy(true, this);
		gtk_do_events();
	}
	
	private void progress_hide(string message = ""){
		toolbar.sensitive = true;		
		hbox_widget.visible = true;		

		vbox_status.visible = false;
		lbl_status.visible = false;
		hbox_progressbar.visible = false;
		progressbar.visible = false;
		btn_cancel_action.visible = false;

		progressbar.fraction = 0.0;
		lbl_status.label = message;

		hbox_credits.visible = true;
		
		//gtk_set_busy(false, this);
		gtk_do_events();
	}
	
	private ConkyConfigItem? selected_item(){
		TreeSelection selection = tv_widget.get_selection();
		TreeModel model;
		TreeIter iter;
		ConkyConfigItem item;
			
		if (selection.count_selected_rows() > 0){
			selection.get_selected(out model, out iter);
			model.get(iter, 1, out item, -1);
			return item;
		}	
		else{
			return null;
		}
	}
	
	//list view handlers

	private void tv_widget_refresh(){
		TreeStore model = new TreeStore(2, typeof(bool), typeof(ConkyConfigItem));
		
		Gee.ArrayList<ConkyConfigItem> list = null;
		if (btn_show_widgets.active){
			list = App.conkyrc_list;
		}
		else{
			list = App.conkytheme_list;
		}
		
		foreach(ConkyConfigItem item in list){
			if ((btn_show_widgets.active) && (App.show_active)){
				if (!item.enabled) { 
					continue; 
				}
			}
			
			TreeIter iter;
			model.append(out iter, null);
			model.set(iter, 0, item.enabled);
			model.set(iter, 1, item);
		}
		
		filterThemes = new TreeModelFilter (model, null);
		filterThemes.set_visible_func(filterThemes_filter);
		tv_widget.set_model (filterThemes);
		tv_widget.columns_autosize();
	}

	private bool filterThemes_filter (Gtk.TreeModel model, Gtk.TreeIter iter){
		if ((txtFilter.text == null)||(txtFilter.text.strip().length == 0)){
			return true;
		}
		
		ConkyConfigItem item;
		model.get (iter, 1, out item, -1);
		
		switch (txtFilter.text.strip().down()){
			case "0":
				return item.enabled;
		}
		
		try{
			Regex regexName = new Regex (txtFilter.text, RegexCompileFlags.CASELESS);
			MatchInfo match;

			if (regexName.match (item.name, 0, out match)) {
				return true;
			}
			else {
				return false;
			}
		}
		catch (Error e) {
			return false;
		}
	}

	private void cell_widget_enable_toggled (string path){
		TreeModel model = filterThemes;
		TreeIter iter;
		bool enabled;
		
		//select clicked row if unselected
		TreeSelection selection = tv_widget.get_selection();
		selection.select_path(new TreePath.from_string(path));
		
		//get state
		model.get_iter_from_string (out iter, path);
		model.get (iter, 0, out enabled, -1);
		
		//toggle
		enabled = !enabled;
		
		if (enabled){
			btn_start_clicked();
		}
		else{
			btn_stop_clicked();
		}
	}
}
